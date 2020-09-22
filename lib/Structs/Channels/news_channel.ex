defmodule Alchemy.Channel.NewsChannel do
  @moduledoc false
  alias Alchemy.OverWrite
  import Alchemy.Structs

  defstruct [
    :id,
    :guild_id,
    :position,
    :permission_overwrites,
    :name,
    :topic,
    :nsfw,
    :last_message_id,
    :parent_id
  ]

  def from_map(map) do
    map
    |> field_map("permission_overwrites", &map_struct(&1, OverWrite))
    |> to_struct(__MODULE__)
  end
end
