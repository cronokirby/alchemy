defmodule Alchemy.Discord.Gateway do
  @moduledoc false
  @behaviour :websocket_client
  require Logger
  import Process
  import Alchemy.Discord.Payloads
  import Alchemy.Discord.Protocol


  defmodule State do
    defstruct [:token, :trace, :session_id, :seq]
  end
  # Requests a gateway URL, before then connecting, and storing the token
  def start_link(token) do
     :crypto.start
     :ssl.start
     url = get_url
     :websocket_client.start_link(url, __MODULE__, %State{token: token})
  end

  def init(state) do
    {:once, state}
  end

  def onconnect(_ws_req, state) do
    Logger.debug "Connected to the gateway"
    {:ok, state}
  end

  def ondisconnect(reason, state) do
    Logger.debug "Disconnected, #{reason}, state: #{IO.inspect state}"
    {:reconnect, state}
  end

  # Messages are either raw, or compressed JSON
  def websocket_handle({:binary, msg}, _conn_state, state) do
      msg |> :zlib.uncompress |> Poison.Parser.parse! |> dispatch(state)
  end
  def websocket_handle({:text, msg}, _conn_state, state) do
      msg |> Poison.Parser.parse! |> dispatch(state)
  end


  # Heartbeats need to be sent every interval
  def websocket_info({:heartbeat, interval}, _conn_state, state) do
    send_after(self(), {:heartbeat, interval}, interval)
    {:reply, {:text, heartbeat(state.seq)}, state}
  end

  # Send the identify package to discord, if this is our fist session
  def websocket_info(:identify, _, %State{session_id: nil} = state) do
    identify = identify_msg(state.token)
    {:reply, {:text, identify}, state}
  end
  # We can resume if we already have a session_id (i.e. we disconnected)
  def websocket_info(:identify, _, state) do
     {:reply, {:text, resume_msg(state)}, state}
  end

  def websocket_terminate(why, _conn_state, state) do
    Logger.info "Websocket terminated, reason: #{IO.inspect why}"
    IO.inspect state
    :ok
  end
end
