defmodule Alchemy.Channel do
  alias Alchemy.OverWrite

  alias Alchemy.Channel.{
    Invite,
    Invite.InviteChannel,
    Invite.InviteGuild,
    TextChannel,
    ChannelCategory,
    VoiceChannel,
    DMChannel,
    GroupDMChannel
  }

  alias Alchemy.User
  import Alchemy.Structs

  @moduledoc """
  This module contains useful functions for operating on `Channels`.
  """

  @typedoc """
  Represents a permission OverWrite object

  - `id`

    role or user id
  - `type`

    either "role", or "member"
  - `allow`

    the bit set of that permission
  - `deny`

    the bit set of that permission
  """
  @type overwrite :: %OverWrite{
          id: String.t(),
          type: String.t(),
          allow: Integer,
          deny: Integer
        }

  @type snowflake :: String.t()
  @type hash :: String.t()
  @type datetime :: String.t()

  @typedoc """
  Represents an Invite object along with the metadata.

  - `code`

    The unique invite code
  - `guild`

    The guild this invite is for
  - `channel`

    The channel this invite is for
  - `inviter`

    The user who created the invite
  - `uses`

    The amount of time this invite has been used
  - `max_uses`

    The max number of times this invite can be used
  - `max_age`

    The duration (seconds) after which the invite will expire
  - `temporary`

    Whether this invite grants temporary membership
  - `created_at`

    When this invite was created
  - `revoked`

    Whether this invite was revoked
  """
  @type invite :: %Invite{
          code: String.t(),
          guild: invite_guild,
          channel: invite_channel,
          inviter: User.t(),
          uses: Integer,
          max_uses: Integer,
          max_age: Integer,
          temporary: Boolean,
          created_at: datetime,
          revoked: Boolean
        }
  @typedoc """
  Represents the guild an invite is for.

  - `id`

    The id of the guild
  - `name`

    The name of the guild
  - `splash`

    The hash of the guild splash (or `nil`)
  - `icon`

    The hash of the guild icon (or `nil`)
  """

  @type invite_guild :: %InviteGuild{
          id: snowflake,
          name: String.t(),
          splash: hash,
          icon: hash
        }
  @typedoc """
  Represents the channel an invite is for

  - `id`

    The id of the channel
  - `name`

    The name of the channel
  - `type`

    The type of the channel, either "text" or "voice"
  """
  @type invite_channel :: %InviteChannel{
          id: snowflake,
          name: String.t(),
          type: String.t()
        }

  @typedoc """
  Represents a normal text channel in a guild

  _ `id`

    The id of the channel
  - `guild_id`

    The id of the guild this channel belongs to
  - `position`

    The sorting position of this channel
  - `permission_overwrites`

    An array of `%OverWrite{}` structs
  - `name`

    The name of this channel
  - `topic`

    The topic of the channel
  - `nsfw`

    Whether or not the channel is considered nsfw
  - `last_message_id`
    
    The id of the last message sent in the channel, if any
  - `parent_id`

    The id of the category this channel belongs to, if any
  - `last_pin_timestamp`

    The timestamp of the last channel pin, if any
  """
  @type text_channel :: %TextChannel{
          id: snowflake,
          guild_id: snowflake,
          position: Integer,
          permission_overwrites: [overwrite],
          name: String.t(),
          topic: String.t() | nil,
          nsfw: Boolean.t(),
          parent_id: snowflake | nil,
          last_message_id: snowflake | nil,
          last_pin_timestamp: String.t() | nil
        }

  @typedoc """
  Represents a channel category in a guild.

  - `id`

    The id of this category
  - `guild_id`

    The of the guild this category belongs to
  - `position`

    The sorting position of this category
  - `permission_overwrites`

    An array of permission overwrites
  - `name`

    The name of this category
  - `nsfw`

    Whether or not this category is considered nsfw
  """
  @type channel_category :: %ChannelCategory{
          id: snowflake,
          guild_id: snowflake,
          position: Integer,
          permission_overwrites: [overwrite],
          name: String.t(),
          nsfw: Boolean.t()
        }

  @typedoc """
  Represents a voice channel in a guild.

  - `id`

    The id of this channel
  - `guild_id`

    The id of the guild this channel belongs to
  - `position`
    
    The sorting position of this channel in the guild
  - `permission_overwrites`

    An array of permission overwrites for this channel
  - `name`

    The name of this channel
  - `nsfw`

    Whether or not this channel is considered nsfw
  - `bitrate`

    The bitrate for this channel
  - `user_limit`

    The max amount of users in this channel, `0` for no limit
  - `parent_id`

    The id of the category this channel belongs to, if any
  """
  @type voice_channel :: %VoiceChannel{
          id: snowflake,
          guild_id: snowflake,
          position: Integer,
          permission_overwrites: [overwrite],
          name: String.t(),
          nsfw: Boolean.t(),
          bitrate: Integer,
          user_limit: Integer,
          parent_id: snowflake | nil
        }

  @typedoc """
  Represents a private message between the bot and another user.

  - `id`

    The id of this channel
  - `recipients`

    A list of users receiving this channel
  - `last_message_id`

    The id of the last message sent, if any
  """
  @type dm_channel :: %DMChannel{
          id: snowflake,
          recipients: [User.t()],
          last_message_id: snowflake | nil
        }

  @typedoc """
  Represents a dm channel between multiple users.

  - `id`

    The id of this channel
  - `owner_id`

    The id of the owner of this channel
  - `icon`

    The hash of the image icon for this channel, if it has one
  - `name`

    The name of this channel
  - `recipients`

    A list of recipients of this channel
  - `last_message_id`
    The id of the last message sent in this channel, if any
  """
  @type group_dm_channel :: %GroupDMChannel{
          id: snowflake,
          owner_id: snowflake,
          icon: String.t() | nil,
          name: String.t(),
          recipients: [User.t()],
          last_message_id: snowflake | nil
        }

  @typedoc """
  The general channel type, representing one of 5 variants.

  The best way of dealing with this type is pattern matching against one of the 5 structs.
  """
  @type t ::
          text_channel
          | voice_channel
          | channel_category
          | dm_channel
          | group_dm_channel

  @doc false
  def from_map(map) do
    case map["type"] do
      0 -> TextChannel.from_map(map)
      1 -> DMChannel.from_map(map)
      2 -> VoiceChannel.from_map(map)
      3 -> GroupDMChannel.from_map(map)
      4 -> ChannelCategory.from_map(map)
    end
  end
end
