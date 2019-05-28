defmodule Alchemy.Channel.GroupDMChannel do
  @moduledoc false
  alias Alchemy.User
  import Alchemy.Structs

  defstruct [:id, :owner_id, :icon, :name, :recipients, :last_message_id]

  def from_map(map) do
    map
    |> field_map("recipients", &map_struct(&1, User))
    |> to_struct(__MODULE__)
  end
end
