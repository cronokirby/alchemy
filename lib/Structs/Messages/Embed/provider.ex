defmodule Alchemy.Embed.Provider do
  @moduledoc """
  """
  @type t :: %__MODULE__{
    name: String.t,
    url: String.t
  }
  @derive Poison.Encoder
  defstruct [:name,
             :url]
end
