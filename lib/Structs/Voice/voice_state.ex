defmodule Alchemy.VoiceState do
  @moduledoc false

  @derive Poison.Encoder
  defstruct [
    :guild_id,
    :channel_id,
    :user_id,
    :session_id,
    :deaf,
    :mute,
    :self_deaf,
    :self_mute,
    :suppress
  ]
end
