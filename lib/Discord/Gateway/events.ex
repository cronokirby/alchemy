defmodule Alchemy.Discord.Events do
  alias Alchemy.DMChannel
  alias Alchemy.Channel
  alias Alchemy.OverWrite
  alias Alchemy.Discord.StateManager, as: State
  import Alchemy.Structs.Utility
  @moduledoc false
  # Used to generate events, and notify the main GenEvent

  # Sends a global event notifcation for people to respond to
  defp notify(msg), do: GenEvent.notify(Events, msg)


  # A direct message was started with the bot
  def handle("CHANNEL_CREATE", %{"is_private" => true} = payload) do
    State.add_priv_channel(payload)
    struct = to_struct(DMChannel, payload)
    GenEvent.notify(Events, {:dm_channel_create, struct})
  end
  def handle("CHANNEL_CREATE", payload) do
    struct = Channel.from_map(payload)
    GenEvent.notify(Events, {:channel_create, struct})
  end

  def handle("CHANNEL_UPDATE", %{"is_private" => true} = payload) do
    State.update_priv_channel(payload)
    notify {:dm_channel_update, to_struct(DMChannel, payload)}
  end
  def handle("CHANNEL_UPDATE", payload) do
    notify {:channel_update, Channel.from_map(payload)}
  end

  def handle("CHANNEL_DELETE", %{"is_private" => true} = payload) do
    State.rem_priv_channel(payload["id"])
    notify {:dm_channel_delete, to_struct(DMChannel, payload)}
  end
  def handle("CHANNEL_UPDATE", payload) do
    notify {:channel_delete, Channel.from_map(payload)}
  end
end
