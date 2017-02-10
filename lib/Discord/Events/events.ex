defmodule Alchemy.Discord.Events do
  alias Alchemy.DMChannel
  alias Alchemy.Channel
  alias Alchemy.Guild
  alias Alchemy.OverWrite
  alias Alchemy.Discord.StateManager, as: State
  import Alchemy.Structs.Utility
  import Alchemy.Discord.EventManager
  @moduledoc false
  # Used to generate events, and notify the main EventManager


  # A direct message was started with the bot
  def handle("CHANNEL_CREATE", %{"is_private" => true} = channel) do
    State.add_priv_channel(channel)
    struct = to_struct(DMChannel, channel)
    {:dm_channel_create, [struct]}
  end
  def handle("CHANNEL_CREATE", channel) do
    struct = Channel.from_map(channel)
    {:channel_create, [struct]}
  end

  def handle("CHANNEL_UPDATE", %{"is_private" => true} = dm_channel) do
    State.update_priv_channel(dm_channel)
    notify {:dm_channel_update, [to_struct(DMChannel, dm_channel)]}
  end
  def handle("CHANNEL_UPDATE", channel) do
    notify {:channel_update, [Channel.from_map(channel)]}
  end

  def handle("CHANNEL_DELETE", %{"is_private" => true} = dm_channel) do
    State.rem_priv_channel(dm_channel["id"])
    notify {:dm_channel_delete, [to_struct(DMChannel, dm_channel)]}
  end
  def handle("CHANNEL_UPDATE", channel) do
    notify {:channel_delete, [Channel.from_map(channel)]}
  end

  # The state manager is tasked of notifying, if, and only if this guild is new,
  # and not in the unavailable guilds loaded before
  def handle("GUILD_CREATE", guild) do
    State.add_guild(guild)
  end

  def handle("GUILD_UPDATE", guild) do
    State.update_guild(guild)
    notify {:guild_update, [Guild.from_map(guild)]}
  end
end
