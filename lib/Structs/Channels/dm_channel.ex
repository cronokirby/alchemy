defmodule Alchemy.DMChannel do
  @moduledoc false
  alias Alchemy.User
  import Alchemy.Structs


  @derive [Poison.Encoder]
  defstruct [:id,
             :recipients,
             :last_message_id
            ]


  @doc false
  def channel_type(code) do
    case code do
      0 -> :text
      1 -> :private
      2 -> :voice
      3 -> :group
      4 -> :guild_category
    end
  end


  def from_map(map) do
    map
    |> field_map("recipients", &map_struct(&1, User))
    |> to_struct(__MODULE__)
  end
end
