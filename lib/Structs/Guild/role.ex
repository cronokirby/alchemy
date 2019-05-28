defmodule Alchemy.Guild.Role do
  @moduledoc false

  @derive Poison.Encoder
  defstruct [:id, :name, :color, :hoist, :position, :permissions, :managed, :mentionable]
end
