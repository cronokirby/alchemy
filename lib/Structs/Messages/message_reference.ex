defmodule Alchemy.MessageReference do
  @moduledoc """
  Represents a reply to a discord message.

  To reply with the bot to a message use it as following:

  ## Examples
  ```elixir
  m = %Alchemy.MessageReference{
     # ID of the message you would like to reply to
     message_id: message_id,
     guild_id: guild_id
  }
  Client.send_message(channel_id, "Reply", message_reference: m)
  ```
  """

  @derive Poison.Encoder
  defstruct [
    :message_id,
    :guild_id,
    channel_id: nil,
    fail_if_not_exists: true
  ]
end
