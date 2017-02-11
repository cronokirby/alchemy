defmodule Alchemy.VoiceState do
  @moduledoc """
  """
  @type t :: %__MODULE__{
    guild_id: String.t,
    channel_id: String.t,
    user_id: String.t,
    session_id: String.t,
    deaf: Boolean,
    mute: Boolean,
    self_deaf: Boolean,
    self_mute: Boolean,
    suppress: Boolean
  }
  @derive Poison.Encoder
  defstruct [:guild_id,
             :channel_id,
             :user_id,
             :session_id,
             :deaf,
             :mute,
             :self_deaf,
             :self_mute,
             :suppress]
end
