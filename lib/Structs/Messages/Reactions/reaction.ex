defmodule Alchemy.Reaction do
  @moduledoc false

  @derive Poison.Encoder
  defstruct [:count, :me, :emoji]
end
