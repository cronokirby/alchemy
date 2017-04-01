defmodule Alchemy.Guild do
  alias Alchemy.Role
  alias Alchemy.Emoji
  alias Alchemy.Channel
  alias Alchemy.GuildMember
  alias Alchemy.VoiceState
  alias Alchemy.Users.Presence
  import Alchemy.Structs
  @moduledoc """
  Guilds represent a collection of users in a "server". This module contains
  information about the types, and subtypes related to guilds, as well
  as some useful functions related to them.
  """
  @type snowflake :: String.t
  @typedoc """
  An iso_8601 timestamp.
  """
  @type timestamp :: String.t
  @typedoc """
  Represents a guild.

  - `id`

    The id of this guild.
  - `name`

    The name of this guild.
  - `icon`
    The image hash of the icon image.
  - `splash`
    The image hash of the splash image. Not a lot of guilds have a hash.
  - `owner_id`
    The user id of the guild's owner.
  - `region`
    The region of the guild.
  - `afk_channel_id`
    The id of the afk channel, if the guild has one.
  - `afk_timeout`
    The afk timeout in seconds.
  - `embed_enabled`
    Whether this guild is embeddable.
  - `verification_level`
    The level of verification this guild requires.
  - `default_message_notifications`
    The default message notifications level.
  - `roles`
    A list of the roles in this server.
  - `emojis`
    A list of custom emojis in this server.
  - `features`
    A list of guild features.
  - `mfa_level`
    The required mfa level for the guild.

  The following fields will be missing for guilds accessed from outside the Cache:
  - `joined_at`
    The timestamp of guild creation.
  - `large`
    Whether or not this guild is considered "large".
  - `unavailable`
    This should never be true for guilds.
  - `member_count`
    The number of members a guild contains.
  - `voice_states`
    A list of voice states of the guild.
  - `members`
    A list of members in the guild.
  - `channels`
    A list of channels in the guild.
  - `presences`
    A list of presences in the guild.
  """
  @type t :: %__MODULE__{
    id: snowflake,
    name: String.t,
    icon: String.t,
    splash: String.t | nil,
    owner: snowflake,
    region: String.t,
    afk_channel_id: String.t | nil,
    afk_timeout: Integer,
    embed_enabled: Boolean,
    verification_level: Integer,
    default_message_notifications: Integer,
    roles: [Role.t],
    emojis: [Emoji.t],
    features: [String.t],
    mfa_level: Integer,
    joined_at: timestamp,
    large: Boolean,
    unavailable: Boolean,
    member_count: Integer,
    voice_states: [VoiceState.t],
    members: [GuildMember.t],
    channels: [Channel.t],
    presences: [Presence.t]
  }

  defstruct [:id,
             :name,
             :icon,
             :splash,
             :owner,
             :region,
             :afk_channel_id,
             :afk_timeout,
             :embed_enabled,
             :verification_level,
             :default_message_notifications,
             :roles,
             :emojis,
             :features,
             :mfa_level,
             :joined_at,
             :large,
             :unavailable,
             :member_count,
             :voice_states,
             :members,
             :channels,
             :presences
             ]

  def from_map(map) do
    map
    |> field_map("roles", &(map_struct &1, Role))
    |> field_map("emojis", &(map_struct &1, Emoji))
    |> field_map("voice_states", &(map_struct &1, VoiceState))
    |> field_map("members", &(map_struct &1, GuildMember))
    |> field_map("channels", &(map_struct &1, Channel))
    |> field_map("presences", &(map_struct &1, Presence))
    |> to_struct(__MODULE__)
  end
end
