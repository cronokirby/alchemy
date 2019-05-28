defmodule Alchemy.Guild.GuildMember do
  alias Alchemy.User
  import Alchemy.Structs
  @moduledoc false

  defstruct [:user, :nick, :roles, :joined_at, :deaf, :mute]

  def from_map(map) do
    map
    |> field("user", User)
    |> to_struct(__MODULE__)
  end
end
