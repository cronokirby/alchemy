defmodule Alchemy.UserGuild do
  @moduledoc false

  @derive [Poison.Encoder]
  defstruct [:id, :name, :icon, :owner, :permissions]
end
