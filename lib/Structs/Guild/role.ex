defmodule Alchemy.Guild.Role do
  @moduledoc """
  """
  @type t :: %__MODULE__{
    id: String.t,
    name: String.t,
    color: Integer,
    hoist: Boolean,
    position: Integer,
    permissions: Integer,
    managed: Boolean,
    mentionable: Boolean,
  }
  @derive Poison.Encoder
  defstruct [:id,
             :name,
             :color,
             :hoist,
             :position,
             :permissions,
             :managed,
             :mentionable,
            ]
end
