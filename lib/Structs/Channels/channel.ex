defmodule Alchemy.Channel do
  alias Alchemy.OverWrite
  alias Alchemy.DMChannel
  alias Alchemy.Channel.{Invite, Invite.InviteChannel, Invite.InviteGuild}
  import Alchemy.DMChannel, only: [channel_type: 1]
  import Alchemy.Structs.Utility
  @moduledoc """
  This module contains useful functions for operating on `Channels`.
  """
  @typedoc """
  Represents a standard channel in a Guild.

  - `id`

    The id of this specific channel. Will be the same as the guild for the "#general"
    channel
  - `guild_id`

    The id of the guild this channel is a part of
  - `name`

    The name of the channel
  - `type`

    `:text`, `:voice`, or `:group`
  - `position`

    Sorting position of the channel
  - `permission_overwrites`

    An array of `%OverWrite{}` objects
  - `topic`

    The topic of a channel, `nil` for voice
  - `last_message_id`

    The id of the last message sent in the channel, `nil` for voice
  - `bitrate`

    The bitrate of a voice channel, `nil` for text
  - `user_limit`

    The user limit of a voice channel, `nil` for text
  """
  @type t :: %__MODULE__{
    id: String.t,
    guild_id: String.t,
    name: String.t,
    type: atom,
    position: Integer,
    permission_overwrites: [overwrite],
    topic: String.t | nil,
    last_message_id: String.t | nil,
    bitrate: Integer | nil,
    user_limit: Integer | nil
  }
  @derive Poison.Encoder
  defstruct [:id,
              :guild_id,
              :name,
              :type,
              :position,
              :permission_overwrites,
              :topic,
              :last_message_id,
              :bitrate,
              :user_limit]
  @typedoc """
  DMChannels represent a private message between 2 users; in this case,
  between a client and a user

  - `id`

    the private channel's id
  - `recipients`

    the users with which the private channel is open
  - `last_message_id`

    The id of the last message sent
  """
  @type dm_channel :: %DMChannel{
    id: String.t,
    type: atom,
    recipients: User.t,
    last_message_id: String.t
  }
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
    id: String.t,
    type: String.t,
    allow: Integer,
    deny: Integer
  }

  @type snowflake :: String.t
  @type hash :: String.t
  @type datetime :: String.t

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
    code: String.t,
    guild: invite_guild,
    channel: invite_channel,
    inviter: User.t,
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

  @type invite_guild ::%InviteGuild{
    id: snowflake,
    name: String.t,
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
    name: String.t,
    type: String.t
  }


  @doc false
  def from_map(map) do
    map
    |> field_map("permission_overwrites", &(map_struct &1, OverWrite))
    |> field_map("type", &channel_type/1)
    |> to_struct(__MODULE__)
  end

end
