defmodule Alchemy.Discord.Events do
  alias Alchemy.{Channel, Emoji, DMChannel, Guild, OverWrite, User,
                 GuildMember, Role}
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

  # The State is responsible for notifications in this case
  def handle("GUILD_DELETE", guild) do
    State.delete(guild)
  end

  def handle("GUILD_BAN_ADD", %{"guild_id" => id} = user) do
    notify {:guild_ban, [to_struct(User, user), id]}
  end

  def handle("GUILD_BAN_REMOVE", %{"guild_id" => id} = user) do
    notify {:guild_unban, [to_struct(User, user), id]}
  end

  def handle("GUILD_EMOJIS_UPDATE", data) do
    State.update_emojis(data)
    notify {:emoji_update, [map_struct(data["emojis"], Emoji), data["guild_id"]]}
  end

  def handle("GUILD_INTEGRATIONS_UPDATE", %{"guild_id" => id}) do
    notify {:integrations_update, [id]}
  end

  def handle("GUILD_MEMBER_ADD", %{"guild_id" => id}) do
    notify {:member_join, [id]}
  end

  def handle("GUILD_MEMBER_REMOVE", %{"guild_id" => id, "user" => user}) do
    State.remove_user(id, user)
    notify {:member_leave, [to_struct(user, User), id]}
  end

  def handle("GUILD_MEMBER_UPDATE", %{"guild_id" => id} = data) do
    # This key would get popped implicitly later, but I'd rather do it clearly here
    State.update_member(id, Map.pop(data, "guild_id"))
    notify {:member_update, [GuildMember.from_mapdata, id]}
  end

  def handle("GUILD_ROLE_CREATE", %{"guild_id" => id, "role" => role}) do
    State.add_role(id, role)
    notify {:role_create, [to_struct(role, Role), id]}
  end

  def handle("GUILD_ROLE_DELETE", %{"guild_id" => guild_id, "role_id" => id}) do
    State.remove_role(guild_id, id)
    notify {:role_delete, [id, guild_id]}
  end

end
