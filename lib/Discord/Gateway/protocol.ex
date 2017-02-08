defmodule Alchemy.Discord.Protocol do
  require Logger
  alias Alchemy.Discord.Gateway
  import Process
  @moduledoc false
  def get_url do
    {:ok, json} = HTTPotion.get("https://discordapp.com/api/v6/gateway").body
                  |> Poison.Parser.parse
    json["url"] <> "?v=6&encoding=json"
  end
  def dispatch(%{"op" => 0, "s" => seq, "d" => payload, "t" => "READY"}, state) do
    Logger.debug "Recieved READY"
    {:ok, %{state | seq: seq,
                    session_id: payload["session_id"],
                    trace: payload["_trace"],
                    parse: false}}
  end
  def dispatch(%{"op" => 7}, state) do
    Logger.debug "Disconnected from the Gateway; restarting the Gateway"
    #Supervisor.restart_child(Client, Gateway)
  end
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
  def dispatch(%{"op" => 11}, state) do
    Logger.debug "ACK response recieved."
    {:ok, state}
  end
  def dispatch(data, state) do
    {:ok, state}
  end


end
