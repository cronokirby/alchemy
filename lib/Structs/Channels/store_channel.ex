defmodule Alchemy.Channel.StoreChannel do
  @moduledoc false
  alias Alchemy.OverWrite
  import Alchemy.Structs

  # Note: should never encounter a store channel, as they're not something
  # bots can send/read to.  It's "the store."
  
  defstruct [
    :id,
    :guild_id,
    :position,
    :permission_overwrites,
    :name,
    :last_message_id,
    :parent_id
  ]

  def from_map(map) do
    map
    |> field_map("permission_overwrites", &map_struct(&1, OverWrite))
    |> to_struct(__MODULE__)
  end
end
