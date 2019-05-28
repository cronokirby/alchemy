defmodule Alchemy.Guild.Presence do
  import Alchemy.Structs
  alias Alchemy.User
  @moduledoc false

  @derive Poison.Encoder
  defstruct [:user, :roles, :game, :guild_id, :status]

  def from_map(map) do
    map
    |> field("user", User)
    |> field_map?("game", &Map.get(&1, "name"))
    |> to_struct(__MODULE__)
  end
end
