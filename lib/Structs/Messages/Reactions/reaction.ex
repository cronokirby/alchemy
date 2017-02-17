defmodule Alchemy.Reaction do
  alias Alchemy.Reaction.Emoji
  @moduledoc """
  """
  @type t :: %__MODULE__{
    count: Integer,
    me: Boolean,
    emoji: Emoji.t
  }
  @derive Poison.Encoder
  defstruct [:count,
             :me,
             :emoji]
end
