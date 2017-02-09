defmodule Alchemy.Users.Presence do
  alias Alchemy.User
  @moduledoc """
  """
  @type t :: %__MODULE__{
    user: User.t,
    roles: [String.t],
    game: Map,
    guild_id: String.t,
    status: String.t
  }
  @derive Poison.Encoder
  defstruct [:user,
             :roles,
             :game,
             :guild_id,
             :status]

end
