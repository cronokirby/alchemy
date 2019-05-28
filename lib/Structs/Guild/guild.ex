defmodule Alchemy.Guild do
  alias Alchemy.{Channel, User, Voice, VoiceState}
  alias Alchemy.Guild.{Emoji, GuildMember, Integration, Presence, Role}
  import Alchemy.Structs

  @moduledoc """
  Guilds represent a collection of users in a "server". This module contains
  information about the types, and subtypes related to guilds, as well
  as some useful functions related to them.
  """
  @type snowflake :: String.t()
  @typedoc """
  An iso_8601 timestamp.
  """
  @type timestamp :: String.t()
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
          name: String.t(),
          icon: String.t(),
          splash: String.t() | nil,
          owner_id: snowflake,
          region: String.t(),
          afk_channel_id: String.t() | nil,
          afk_timeout: Integer,
          embed_enabled: Boolean,
          verification_level: Integer,
          default_message_notifications: Integer,
          roles: [Guild.role()],
          emojis: [emoji],
          features: [String.t()],
          mfa_level: Integer,
          joined_at: timestamp,
          large: Boolean,
          unavailable: Boolean,
          member_count: Integer,
          voice_states: [Voice.state()],
          members: [member],
          channels: [Channel.t()],
          presences: [Presence.t()]
        }

  defstruct [
    :id,
    :name,
    :icon,
    :splash,
    :owner_id,
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

  @typedoc """
  Represents a member in a guild.

  - `user`
    A user struct containing information about the underlying user.
  - `nick`
    An optional nickname for this member.
  - `roles`
    A list of ids corresponding to roles the member has.
  - `joined_at`
    The timestamp of when this member joined the guild.
  - `deaf`
    Whether the user is currently deafened.
  - `mute`
    Whether the user is currently muted.
  """
  @type member :: %GuildMember{
          user: User.t(),
          nick: String.t() | nil,
          roles: [snowflake],
          joined_at: timestamp,
          deaf: Boolean,
          mute: Boolean
        }
  @typedoc """
  Represents a custom emoji in a guild.

  The string representation of this struct will be the markdown
  necessary to use it. i.e. `Cogs.say("\#{emoji}")` will send the emoji.

  - `id`
    The id of this emoji.
  - `name`
    The name of this emoji.
  - `roles`
    A list of role ids who can use this role.
  - `require_colons`
    Whether or not this emoji must be wrapped in colons.
  - `managed`
    Whether or not this emoji is managed.
  """
  @type emoji :: %Emoji{
          id: String.t(),
          name: String.t(),
          roles: [String.t()],
          require_colons: Boolean,
          managed: Boolean
        }
  @typedoc """
  Represents the account of an integration.

  - `id`
    The id of the account.
  - `name`
    The name of the account.
  """
  @type integration_account :: %Integration.Account{
          id: snowflake,
          name: String.t()
        }
  @typedoc """
  Represents an guild's integration with a service, (i.e. twitch)

  - `id`
    The id of the integration.
  - `name`
    The name of the integration.
  - `type`
    Integration type; youtube, twitch, etc.
  - `enabled`
    Whether or not the integration is enabled.
  - `syncing`
    Whether or not the integration is syncing.
  - `role_id`
    The id of the role associated with "subscribers" to this integration.
  - `expire_behaviour`
    The behaviour of expiring subscribers.
  - `expire_grace_period`
    The grace period before expiring subscribers.
  - `user`
    The user for this integration.
  - `account`
    The integration's account information.
  - `synced_at`
    When this integration was last synced.
  """
  @type integration :: %Integration{
          id: snowflake,
          name: String.t(),
          type: String.t(),
          enabled: Boolean,
          syncing: Boolean,
          role_id: snowflake,
          expire_behaviour: Integer,
          expire_grace_period: Integer,
          user: User.t(),
          account: integration_account,
          synced_at: timestamp
        }

  @typedoc """
  Represents a role in a guild.

  - `id`
    The id of the role.
  - `name`
    The name of the role.
  - `color`
    The color of the role.
  - `hoist`
    Whether the role is "hoisted" above others in the sidebar.
  - `position`
    The position of the role in a guild.
  - `permissions`
    The bitset of permissions for this role. See the `Permissions` module
    for more information.
  - `managed`
    Whether this role is managed by an integration.
  - `mentionable`
    Whether this role is mentionable.
  """
  @type role :: %Role{
          id: snowflake,
          name: String.t(),
          color: Integer,
          hoist: Boolean,
          position: Integer,
          permissions: Integer,
          managed: Boolean,
          mentionable: Boolean
        }
  @typedoc """
  Represents the presence of a user in a guild.

  - `user`
    The user this presence is for.
  - `roles`
    A list of role ids this user belongs to.
  - `game`
    The current activity of the user, or `nil`.
  - `guild_id`
    The id of the guild this presences is in.
  - `status`
    "idle", "online", or "offline"
  """
  @type presence :: %Presence{
          user: User.t(),
          roles: [snowflake],
          game: String.t() | nil,
          guild_id: snowflake,
          status: String.t()
        }

  @doc """
  Finds the highest ranked role of a member in a guild.

  This is useful, because the permissions and color 
  of the highest role are the ones that apply to that member.
  """
  @spec highest_role(t, member) :: role
  def highest_role(guild, member) do
    guild.roles
    |> Enum.sort_by(& &1.position)
    # never null because of the @everyone role 
    |> Enum.find(&(&1 in member.roles))
  end

  defmacrop is_valid_guild_icon_url(type, size) do
    quote do
      unquote(type) in ["jpg", "jpeg", "png", "webp"] and
        unquote(size) in [128, 256, 512, 1024, 2048]
    end
  end

  @doc """
  Get the icon image URL for the given guild.
  If the guild does not have any icon, returns `nil`.

  ## Parameters
  - `type`: The returned image format. Can be any of `jpg`, `jpeg`, `png`, or `webp`.
  - `size`: The desired size of the returned image. Must be a power of two.
  If the parameters do not match these conditions, an `ArgumentError` is raised.
  """
  @spec icon_url(__MODULE__.t(), String.t(), 16..2048) :: String.t()
  def icon_url(guild, type \\ "png", size \\ 256) when is_valid_guild_icon_url(type, size) do
    case guild.icon do
      nil -> nil
      hash -> "https://cdn.discordapp.com/icons/#{guild.id}/#{hash}.#{type}?size=#{size}"
    end
  end

  def icon_url(_guild, _type, _size) do
    raise ArgumentError, message: "invalid icon URL type and / or size"
  end

  @doc false
  def from_map(map) do
    map
    |> field_map("roles", &map_struct(&1, Role))
    |> field_map("emojis", &map_struct(&1, Emoji))
    |> field_map?("voice_states", &map_struct(&1, VoiceState))
    |> fields_from_map?("members", GuildMember)
    |> fields_from_map?("channels", Channel)
    |> fields_from_map?("presences", Presence)
    |> to_struct(__MODULE__)
  end
end
