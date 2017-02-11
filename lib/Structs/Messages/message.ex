defmodule Alchemy.Message do
  alias Alchemy.User
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
    attachments: String.t,
    embeds: String.t,
    reactions: String.t,
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
end
