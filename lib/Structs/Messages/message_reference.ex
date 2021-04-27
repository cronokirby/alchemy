defmodule Alchemy.MessageReference do
  @moduledoc false

  @derive Poison.Encoder
  defstruct [
    :message_id,
    :guild_id,
    channel_id: nil,
    fail_if_not_exists: true
  ]
end
