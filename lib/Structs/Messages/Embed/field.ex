defmodule Alchemy.Embed.Field do
  @moduledoc false

  @derive Poison.Encoder
  defstruct [:name, :value, :inline]
end
