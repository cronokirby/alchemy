defmodule Alchemy.Embed.Video do
  @moduledoc """
  """
  @type t :: %__MODULE__{
    url: String.t,
    height: Integer,
    width: Integer
  }
  @derive Poison.Encoder
  defstruct [:url,
             :height,
             :width]
end
