defmodule Alchemy.Guild.Emoji do
  @moduledoc """
  """
  @type t :: %__MODULE__{
    id: String.t,
    name: String.t,
    roles: [String.t],
    require_colons: Boolean,
    managed: Boolean
  }
  @derive Poison.Encoder
  defstruct [:id,
             :name,
             :roles,
             :require_colons,
             :managed]
end
