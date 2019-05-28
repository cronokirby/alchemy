defmodule Alchemy.Channel.DMChannel do
  @moduledoc false
  alias Alchemy.User
  import Alchemy.Structs

  @derive [Poison.Encoder]
  defstruct [:id, :recipients, :last_message_id]

  def from_map(map) do
    map
    |> field_map("recipients", &map_struct(&1, User))
    |> to_struct(__MODULE__)
  end
end
