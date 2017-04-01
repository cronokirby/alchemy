defmodule Alchemy.Reaction do
  alias Alchemy.Reaction.Emoji
  @moduledoc false

  @derive Poison.Encoder
  defstruct [:count,
             :me,
             :emoji]
end
