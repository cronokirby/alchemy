defmodule Alchemy.Guild.Presence do
  import Alchemy.Structs
  alias Alchemy.User
  @moduledoc """
  """
  @type t :: %__MODULE__{
    user: User.t,
    roles: [String.t],
    game: String.t | nil,
    guild_id: String.t,
    status: String.t
  }
  @derive Poison.Encoder
  defstruct [:user,
             :roles,
             :game,
             :guild_id,
             :status]

  def from_map(map) do
    map
    |> field("user", User)
    |> field_map?("game", &Map.get(&1, "name"))
    |> to_struct(__MODULE__)
  end

end
