defmodule Alchemy.Discord.Protocol do
  require Logger
  import Process
  import Alchemy.Discord.Payloads
  alias Alchemy.Discord.Gateway
  @moduledoc false


  def get_url do
    {:ok, json} = HTTPotion.get("https://discordapp.com/api/v6/gateway").body
                  |> Poison.Parser.parse
    json["url"] <> "?v=6&encoding=json"
  end


  # Immediate heartbeat request
  def dispatch(%{"op" => 1}, state) do
    {:reply, {:text, heartbeat(state.seq)}, state}
  end
  # Disconnection warning
  def dispatch(%{"op" => 7}, state) do
    Logger.debug "Disconnected from the Gateway; restarting the Gateway"
  end
  # Invalid session_id. This is quite fatal.
  def dispatch(%{"op" => 9}, state) do
    raise "Invalid session id! see logs for info."
  end
  # Heartbeat payload, defining the interval to beat to
  def dispatch(%{"op" => 10, "d" => payload}, state) do
    Logger.debug "Recieved heartbeat message"
    interval = payload["heartbeat_interval"]
    send(self(), :identify)
    send_after(self(), {:heartbeat, interval}, interval)
    {:ok, %{state | trace: payload["_trace"]}}
  end
  # Heartbeat ACK, doesn't do anything noteworthy
  def dispatch(%{"op" => 11}, state) do
    {:ok, state}
  end
  # Need to fill this in
  def dispatch(data, state) do
    {:ok, state}
  end

  # The READY event, part of the standard protocol
  def dispatch(%{"t" => "READY", "s" => seq, "d" => payload}, state) do
    Logger.debug "Recieved READY"
    {:ok, %{state | seq: seq,
                    session_id: payload["session_id"],
                    trace: payload["_trace"]}}
  end

end
