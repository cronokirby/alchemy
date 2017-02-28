defmodule Alchemy.DMChannel do
  @moduledoc false
  alias Alchemy.User
  import Alchemy.Structs.Utility


  @derive [Poison.Encoder]
  defstruct [:id,
             :type,
             :recipients,
             :last_message_id
            ]


  @doc false
  def channel_type(code) do
    case code do
      -1 -> :text
      0 -> :private
      1 -> :voice
      2 -> :group
    end
  end


  def from_map(map) do
    map
    |> field_map("type", &channel_type/1)
    |> field_map("recipients", &map_struct(&1, User))
    |> to_struct(__MODULE__)
  end


end
