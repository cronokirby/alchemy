defmodule Alchemy.Embed.Field do
  @moduledoc """
  """
  @type t :: %__MODULE__{
    name: String.t,
    value: String.t,
    inline: Boolean
  }
  @derive Poison.Encoder
  defstruct [:name,
             :value,
             :inline]
end
