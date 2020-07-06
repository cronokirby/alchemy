defmodule Alchemy.Discord.Events do
  # This module contains the protocols
  @moduledoc false
  # for updating the cache based on the events received from discord.
  # This module is then used by EventStage.Cache
  alias Alchemy.{Channel, Channel.DMChannel, Guild.Emoji, Guild, Message, User, VoiceState}
  alias Alchemy.Guild.{GuildMember, Presence, Role}
  alias Alchemy.Cache.{Channels, Guilds, PrivChannels}
  import Alchemy.Structs

  # A direct message was started with the bot
  # type 1 == DM
  # https://discord.com/developers/docs/resources/channel#channel-object-channel-types
  def handle("CHANNEL_CREATE", %{"type" => 1} = dm_channel) do
    PrivChannels.add_channel(dm_channel)
    struct = to_struct(dm_channel, DMChannel)
    {:dm_channel_create, [struct]}
  end

  def handle("CHANNEL_CREATE", %{"guild_id" => guild_id} = channel) do
    struct = Channel.from_map(channel)
    Guilds.add_channel(guild_id, channel)

    {:channel_create, [struct]}
  end

  def handle("CHANNEL_UPDATE", %{"id" => channel_id} = channel) do
    with {:ok, guild_id} <- Channels.lookup(channel_id) do
      Guilds.update_channel(guild_id, channel)
    end
    {:channel_update, [Channel.from_map(channel)]}
  end

  def handle("CHANNEL_DELETE", %{"type" => 1} = dm_channel) do
    PrivChannels.remove_channel(dm_channel["id"])
    {:dm_channel_delete, [to_struct(dm_channel, DMChannel)]}
  end

  def handle("CHANNEL_DELETE", %{"id" => channel_id} = channel) do
    with {:ok, guild_id} <- Channels.lookup(channel_id) do
      Guilds.remove_channel(guild_id, channel_id)
    end
    Channels.remove_channel(channel_id)
    {:channel_delete, [Channel.from_map(channel)]}
  end

  # The Cache manager is tasked of notifying, if, and only if this guild is new,
  # and not in the unavailable guilds loaded before
  def handle("GUILD_CREATE", guild) do
    Guilds.add_guild(guild)
  end

  def handle("GUILD_UPDATE", guild) do
    guild =
      Guilds.update_guild(guild)
      |> Guilds.de_index()
      |> Guild.from_map()

    {:guild_update, [guild]}
  end

  # The Cache is responsible for notifications in this case
  def handle("GUILD_DELETE", guild) do
    Guilds.remove_guild(guild)
  end

  def handle("GUILD_BAN_ADD", %{"guild_id" => id} = user) do
    {:guild_ban, [to_struct(user, User), id]}
  end

  def handle("GUILD_BAN_REMOVE", %{"guild_id" => id} = user) do
    {:guild_unban, [to_struct(user, User), id]}
  end

  def handle("GUILD_EMOJIS_UPDATE", data) do
    Guilds.update_emojis(data)
    {:emoji_update, [map_struct(data["emojis"], Emoji), data["guild_id"]]}
  end

  def handle("GUILD_INTEGRATIONS_UPDATE", %{"guild_id" => id}) do
    {:integrations_update, [id]}
  end

  def handle("GUILD_MEMBER_ADD", %{"guild_id" => id}) do
    {:member_join, [id]}
  end

  def handle("GUILD_MEMBERS_CHUNK", %{"guild_id" => id, "members" => m}) do
    Guilds.add_members(id, m)
    {:member_chunk, [id, Enum.map(m, &GuildMember.from_map/1)]}
  end

  def handle("GUILD_MEMBER_REMOVE", %{"guild_id" => id, "user" => user}) do
    Guilds.remove_member(id, user)
    {:member_leave, [to_struct(user, User), id]}
  end

  def handle("GUILD_MEMBER_UPDATE", %{"guild_id" => id} = data) do
    # This key would get popped implicitly later, but I'd rather do it clearly here
    Guilds.update_member(id, Map.delete(data, "guild_id"))
    {:member_update, [GuildMember.from_map(data), id]}
  end

  def handle("GUILD_ROLE_CREATE", %{"guild_id" => id, "role" => role}) do
    Guilds.add_role(id, role)
    {:role_create, [to_struct(role, Role), id]}
  end

  def handle("GUILD_ROLE_UPDATE", %{"guild_id" => id, "role" => new_role = %{"id" => role_id}}) do
    guild_result = Guilds.safe_call(id, {:section, "roles"})
    old_role =
      with {:ok, guild} <- guild_result,
           role when not is_nil(role) <- guild[role_id]
      do
        to_struct(role, Role)
      else
        _ -> nil
      end

    Guilds.update_role(id, new_role)
    new_role = to_struct(new_role, Role)
    {:role_update, [old_role, new_role, id]}
  end

  def handle("GUILD_ROLE_DELETE", %{"guild_id" => guild_id, "role_id" => id}) do
    Guilds.remove_role(guild_id, id)
    {:role_delete, [id, guild_id]}
  end

  def handle("MESSAGE_CREATE", message) do
    struct = Message.from_map(message)
    {:message_create, [struct]}
  end

  def handle("MESSAGE_UPDATE", message) do
    {:message_update, [Message.from_map(message)]}
  end

  def handle("MESSAGE_DELETE", %{"id" => msg_id, "channel_id" => chan_id}) do
    {:message_delete, [msg_id, chan_id]}
  end

  def handle("MESSAGE_DELETE_BULK", %{"ids" => ids, "channel_id" => chan_id}) do
    {:message_delete_bulk, [ids, chan_id]}
  end

  def handle("MESSAGE_REACTION_ADD", %{
        "user_id" => user_id,
        "channel_id" => channel_id,
        "message_id" => message_id,
        "emoji" => emoji
      }) do
    {:message_reaction_add, [user_id, channel_id, message_id, emoji]}
  end

  def handle("MESSAGE_REACTION_REMOVE", %{
        "user_id" => user_id,
        "channel_id" => channel_id,
        "message_id" => message_id,
        "emoji" => emoji
      }) do
    {:message_reaction_remove, [user_id, channel_id, message_id, emoji]}
  end

  def handle("MESSAGE_REACTION_REMOVE_ALL", %{
        "channel_id" => channel_id,
        "message_id" => message_id
      }) do
    {:message_reaction_remove_all, [channel_id, message_id]}
  end

  def handle("PRESENCE_UPDATE", %{"guild_id" => _id} = presence) do
    Guilds.update_presence(presence)
    {:presence_update, [Presence.from_map(presence)]}
  end

  def handle("PRESENCE_UPDATE", presence) do
    {:presence_update, [Presence.from_map(presence)]}
  end

  def handle("READY", payload) do
    {:ready, payload["shard"]}
  end

  def handle("TYPING_START", data) do
    chan_id = data["channel_id"]
    user_id = data["user_id"]
    timestamp = data["timestamp"]
    {:typing_start, [user_id, chan_id, timestamp]}
  end

  def handle("USER_SETTINGS_UPDATE", %{"username" => name, "avatar" => avatar}) do
    {:user_settings_update, [name, avatar]}
  end

  def handle("USER_UPDATE", user) do
    {:user_update, [to_struct(user, User)]}
  end

  def handle("VOICE_STATE_UPDATE", voice) do
    Guilds.update_voice_state(voice)
    {:voice_state_update, [to_struct(voice, VoiceState)]}
  end

  def handle(_, _) do
    {:unkown, []}
  end
end
