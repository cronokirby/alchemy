defmodule Alchemy.Voice.Gateway do
  @moduledoc false
  @behaviour :websocket_client
  alias Alchemy.Voice.Supervisor.Registry

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
  end

  defmodule State do
    @moduledoc false
    defstruct [:token, :guild_id, :user_id, :url, :session]
  end

  def start_link(url, token, session, user_id, guild_id) do
    :crypto.start()
    :ssl.start()
    state = %State{token: token, guild_id: guild_id, user_id: user_id,
                   url: url, session: session}
    :websocket_client.start_link("wss://" <> url, __MODULE__, state,
                                 name: Registry.via({guild_id, :gateway}))
  end

  def init(state) do
    {:once, state}
  end

  def onconnect(_, state) do
    payload = Payloads.identify(state.guild_id, state.user_id,
                                state.session, state.token)
    {:reply, {:text, payload}, state}
  end

  def websocket_handle({:text, msg}, _, state) do
    msg |> Poison.Parser.parse! |> dispatch(state)
  end

  def dispatch(%{"op" => 2, "d" => payload}, state) do

  end

  def dispatch(_, state) do
    {:ok, state}
  end
end
