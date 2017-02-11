defmodule Alchemy.Reaction.Emoji do
  @moduledoc """
  """
  @type t :: %__MODULE__{
    id: String.t,
    name: String.t
  }
  @derive Poison.Encoder
  defstruct [:id,
             :name]
end
