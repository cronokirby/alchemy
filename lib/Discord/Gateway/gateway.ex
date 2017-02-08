defmodule Alchemy.Discord.Gateway do
  @moduledoc false
  import Process
  import Alchemy.Discord.Payloads
  import Alchemy.Discord.Protocol
  require Logger
  @behaviour :websocket_client

  defmodule State do
    defstruct [:token, :trace, :session_id, :seq, parse: true]
  end
  def start_link(token) do
     :crypto.start
     :ssl.start
     url = get_url
     :websocket_client.start_link(url, __MODULE__, %State{token: token})
  end

  def init(state) do
    {:once, state}
  end

  def send(msg) do
    send(self(), :start)
  end

  def onconnect(_ws_req, state) do
    Logger.debug "Connected"
    {:ok, state}
  end

  def ondisconnect(reason, state) do
    Logger.debug "Disconnected, #{reason}, state: #{IO.inspect state}"
    {:reconnect, state}
  end

  def websocket_handle({:binary, msg}, _conn_state, state) do
      if true do
        msg |> :zlib.uncompress |> Poison.Parser.parse! |> dispatch(state)
      else
        Logger.debug "ignoring"
        {:ok, state}
      end
  end
  def websocket_handle({:text, msg}, _conn_state, state) do
    if true do
      msg |> Poison.Parser.parse! |> dispatch(state)
    else
      Logger.debug "ignoring"
      {:ok, state}
    end
  end


  def websocket_info({:heartbeat, interval}, _conn_state, state) do
    Logger.debug "Sending a beat"
    send_after(self(), {:heartbeat, interval}, interval)
    {:reply, {:text, heartbeat(state.seq)}, state}
  end

  def websocket_info(:identify, _, %State{session_id: nil} = state) do
    identify = identify_msg(state.token)
    {:reply, {:text, identify}, state}
  end
  def websocket_info(:identify, _, state) do
     {:reply, {:text, resume_msg(state)}, state}
  end

  def websocket_terminate(why, _conn_state, state) do
    Logger.info "Websocket terminated, reason: #{IO.inspect why}"
    IO.inspect state
    :ok
  end
end
