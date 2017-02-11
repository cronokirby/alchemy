defmodule Alchemy.Message do
  import Alchemy.Structs.Utility
  alias Alchemy.Structs.Utility
  alias Alchemy.{User, Attachment, Embed, Reaction}
  @moduledoc """
  """
  @type t :: %__MODULE__{
    id: String.t,
    channel_id: String.t,
    author: User.t,
    content: String,
    timestamp: String,
    edited_timestamp: String | nil,
    tts: Boolean,
    mention_everyone: Boolean,
    mentions: [User.t],
    mention_roles: [String.t],
    attachments: [Attachment.t],
    embeds: [Embed.t],
    reactions: [Reaction.t],
    nonce: String.t,
    pinned: Boolean,
    webhook_id: String.t
  }
  @derive Poison.Encoder
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

  def from_map(map) do
    map
    |> field("author", User)
    |> field_map("mentions", &map_struct(&1, User))
    |> field_map("attachements", &map_struct(&1, Attachment))
    |> field_map("embed", &Enum.map(&1, fn x -> Embed.from_map(x) end))
    |> field_map("reactions", &map_struct(&1, Reaction))
    |> to_struct(Message)
  end
end
