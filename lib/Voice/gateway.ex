defmodule Alchemy.Voice.Gateway do
  @moduledoc false
  @behaviour :websocket_client
  alias Alchemy.Voice.Supervisor.{Registry, Server}
  alias Alchemy.Voice.Controller
  alias Alchemy.Voice.UDP
  require Logger

  defmodule Payloads do
    @opcodes %{
      identify: 0,
      select: 1,
      ready: 2,
      heartbeat: 3,
      session: 4,
      speaking: 5
    }

    def build_payload(data, op) do
      %{op: @opcodes[op], d: data}
      |> Poison.encode!
    end

    def identify(server_id, user_id, session, token) do
      %{"server_id" => server_id, "user_id" => user_id,
        "session_id" => session, "token" => token}
        |> build_payload(:identify)
    end

    def heartbeat do
      now = DateTime.utc_now() |> DateTime.to_unix
      build_payload(now * 1000, :heartbeat)
    end

    def select(my_ip, my_port) do
      %{"protocol" => "udp", "data" => %{
        "address" => my_ip, "port" => my_port,
        "mode" => "xsalsa20_poly1305"
        }}
      |> build_payload(:select)
    end
  end

  defmodule State do
    @moduledoc false
    defstruct [:token, :guild_id, :user_id, :url, :session, :udp,
               :discord_ip, :discord_port, :my_ip, :my_port]
  end

  def start_link(url, token, session, user_id, guild_id) do
    :crypto.start()
    :ssl.start()
    url = String.replace(url, ":80", "")
    state = %State{token: token, guild_id: guild_id, user_id: user_id,
                   url: url, session: session}
    :websocket_client.start_link("wss://" <> url, __MODULE__, state,
                                 name: Registry.via({guild_id, :gateway}))
  end

  def init(state) do
    {:once, state}
  end

  def onconnect(_, state) do
    Logger.debug "Voice Gateway for #{state.guild_id} connected"
    payload = Payloads.identify(state.guild_id, state.user_id,
                                state.session, state.token)
    send(self(), :send_identify)
    {:ok, state}
  end

  def ondisconnect(reason, state) do
    Logger.debug("Voice Gateway for #{state.guild_id} disconnected, "
                 <> "reason: #{inspect reason}")
    if state.udp do
      :gen_udp.close(state.udp)
    end
    {:reconnect, state}
  end

  def websocket_handle({:text, msg}, _, state) do
    msg |> Poison.Parser.parse! |> dispatch(state)
  end

  def dispatch(%{"op" => 2, "d" => payload}, state) do
    {my_ip, my_port, discord_ip, udp} =
      UDP.open_udp(state.url, payload["port"], payload["ssrc"])
    new_state =
      %{state | my_ip: my_ip, my_port: my_port,
                discord_ip: discord_ip, discord_port: payload["port"]}
    send(self(), {:heartbeat, payload["heartbeat_interval"]})
    start_controller(udp, new_state)
    {:reply, {:text, Payloads.select(my_ip, my_port)}, state}
  end

  def dispatch(_, state) do
    {:ok, state}
  end

  def websocket_info(:send_identify, _, state) do
    payload = Payloads.identify(state.guild_id, state.user_id,
                                state.session, state.token)
    {:reply, {:text, payload}, state}
  end

  def websocket_info({:heartbeat, interval}, _, state) do
    Process.send_after(self(), {:heartbeat, interval}, interval)
    {:reply, {:text, Payloads.heartbeat()}, state}
  end

  def start_controller(udp, state) do
    {:ok, pid} =
      Controller.start_link(udp, state.discord_ip, state.discord_port,
                            state.guild_id)
    Server.send_to(state.guild_id, pid)
  end
end
