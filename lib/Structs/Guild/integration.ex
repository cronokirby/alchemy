defmodule Alchemy.Guild.Integration do
  @moduledoc false
  alias Alchemy.User
  import Alchemy.Structs

  defstruct [
    :id,
    :name,
    :type,
    :enabled,
    :syncing,
    :role_id,
    :expire_behaviour,
    :expire_grace_period,
    :user,
    :account,
    :synced_at
  ]

  defmodule Account do
    @moduledoc false
    defstruct [:id, :name]
  end

  def from_map(map) do
    map
    |> field("user", User)
    |> field("account", Account)
    |> to_struct(__MODULE__)
  end
end
