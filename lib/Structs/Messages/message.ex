defmodule Alchemy.Message do
  import Alchemy.Structs
  alias Alchemy.{User, Attachment, Embed, Reaction}
  @moduledoc """
  This module contains the types and functions related to messages in discord.
  """

  @type snowflake :: String.t
  @typedoc """
  Represents an iso8601 timestamp.
  """
  @type timestamp :: String.t
  @typedoc """
  Represents a message in a channel.

  - `id`
    The id of this message.
  - `author`
    The user who sent this message. This field will be very incomplete
    if the message originated from a webhook.
  - `content`
    The content of the message.
  - `timestamp`
    The timestamp of the message.
  - `edit_timestamp`
    The timestamp of when this message was edited, if it ever was.
  - `tts`
    Whether this was a tts message.
  - `mention_everyone`
    Whether this message mentioned everyone.
  - `mentions`
    A list of users this message mentioned.
  - `mention_roles`
    A list of role ids this message mentioned.
  - `attachments`
    A list of attachments to the message.
  - `embeds`
    A list of embeds attached to this message.
  - `reactions`
    A list of reactions to this message.
  - `nonce`
    Used for validating a message was sent.
  - `pinned`
    Whether this message is pinned.
  - `webhook_id`
    The id of the webhook that sent this message, if it was sent by a webhook.
  """
  @type t :: %__MODULE__{
    id: snowflake,
    channel_id: snowflake,
    author: User.t,
    content: String,
    timestamp: timestamp,
    edited_timestamp: String | nil,
    tts: Boolean,
    mention_everyone: Boolean,
    mentions: [User.t],
    mention_roles: [snowflake],
    attachments: [Attachment.t],
    embeds: [Embed.t],
    reactions: [Reaction.t],
    nonce: snowflake,
    pinned: Boolean,
    webhook_id: String.t | nil
  }

  defstruct [:id,
             :channel_id,
             :author,
             :content,
             :timestamp,
             :edited_timestamp,
             :tts,
             :mention_everyone,
             :mentions,
             :mention_roles,
             :attachments,
             :embeds,
             :reactions,
             :nonce,
             :pinned,
             :webhook_id
             ]

  @typedoc """
  Represents a reaction to a message.

  - `count`
    Times this specific emoji reaction has been used.
  - `me`
    Whether this client reacted to the message.
  - `emoji`
    Information about the emoji used.
  """
  @type reaction :: %Reaction{
    count: Integer,
    me: Boolean,
    emoji: Emoji.t
  }
  @typedoc """
  Represents an emoji used to react to a message.

  - `id`
    The id of this emoji. `nil` if this isn't a custom emoji.
  - `name`
    The name of this emoji.
  """
  @type emoji :: %Emoji{
    id: String.t | nil,
    name: String.t
  }

  @doc false
  def from_map(map) do
    map
    |> field?("author", User)
    |> field_map?("mentions", &map_struct(&1, User))
    |> field_map?("attachments", &map_struct(&1, Attachment))
    |> field_map("embeds", &Enum.map(&1, fn x -> Embed.from_map(x) end))
    |> field_map?("reactions", &map_struct(&1, Reaction))
    |> to_struct(__MODULE__)
  end

end
