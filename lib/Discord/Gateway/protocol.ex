defmodule Alchemy.Discord.Protocol do
  @moduledoc false
  require Logger
  alias Alchemy.EventStage.EventBuffer
  alias Alchemy.Voice.Supervisor.Server
  alias Alchemy.Cache.Supervisor, as: Cache
  import Alchemy.Discord.Payloads

  # Immediate heartbeat request
  def dispatch(%{"op" => 1}, state) do
    {:reply, {:text, heartbeat(state.seq)}, state}
  end

  # Disconnection warning
  def dispatch(%{"op" => 7}, state) do
    Logger.debug(
      "Shard " <>
        inspect(state.shard) <>
        " Disconnected from the Gateway; restarting the Gateway"
    )
  end

  # Invalid session_id. This is quite fatal.
  def dispatch(%{"op" => 9}, state) do
    Logger.debug(
      "Shard #{inspect(state.shard)} " <>
        "connected with an invalid session id"
    )

    Process.exit(self(), :brutal_kill)
  end

  # Heartbeat payload, defining the interval to beat to
  def dispatch(%{"op" => 10, "d" => payload}, state) do
    interval = payload["heartbeat_interval"]
    send(self(), :identify)
    Process.send_after(self(), {:heartbeat, interval}, interval)
    {:ok, %{state | trace: payload["_trace"]}}
  end

  # Heartbeat ACK, doesn't do anything noteworthy
  def dispatch(%{"op" => 11}, state) do
    {:ok, state}
  end

  # The READY event, part of the standard protocol
  def dispatch(%{"t" => "READY", "s" => seq, "d" => payload}, state) do
    Cache.ready(
      payload["user"],
      payload["private_channels"],
      payload["guilds"]
    )

    EventBuffer.notify({"READY", Map.put(payload, "shard", state.shard)})
    Logger.debug("Shard #{inspect(state.shard)} received READY")

    {:ok,
     %{
       state
       | seq: seq,
         session_id: payload["session_id"],
         trace: payload["_trace"],
         user_id: payload["user"]["id"]
     }}
  end

  # Sent after resuming to the gateway
  def dispatch(%{"t" => "RESUMED", "d" => payload}, state) do
    Logger.debug("Shard #{inspect(state.shard)} resumed gateway connection")
    {:ok, %{state | trace: payload["_trace"]}}
  end

  def dispatch(%{"t" => "VOICE_SERVER_UPDATE", "d" => payload, "s" => seq}, state) do
    Server.send_to(payload["guild_id"], {payload["token"], payload["endpoint"]})
    {:ok, %{state | seq: seq}}
  end

  def dispatch(
        %{"t" => "VOICE_STATE_UPDATE", "s" => seq, "d" => %{"user_id" => u} = payload},
        %{user_id: u} = state
      ) do
    Server.send_to(payload["guild_id"], {u, payload["session_id"]})
    EventBuffer.notify({"VOICE_STATE_UPDATE", payload})
    {:ok, %{state | seq: seq}}
  end

  def dispatch(%{"t" => type, "d" => payload, "s" => seq}, state) do
    EventBuffer.notify({type, payload})
    {:ok, %{state | seq: seq}}
  end
end
