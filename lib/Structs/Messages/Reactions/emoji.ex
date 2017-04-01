defmodule Alchemy.Reaction.Emoji do
  @moduledoc false

  @derive Poison.Encoder
  defstruct [:id,
             :name]


  @doc false
  def resolve(emoji) do
    case emoji do
      %__MODULE__{} = em -> em
      unicode -> %__MODULE__{name: unicode}
    end
  end
end
