defmodule Alchemy.OverWrite do
  @moduledoc false

  @derive Poison.Encoder
  defstruct [:id, :type, :allow, :deny]
end
