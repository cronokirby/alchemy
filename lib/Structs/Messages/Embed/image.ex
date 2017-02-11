defmodule Alchemy.Embed.Image do
  @moduledoc """
  """

  @type t :: %__MODULE__{
    url: String.t,
    proxy_url: String.t,
    height: Integer,
    width: Integer
  }
  @derive Poison.Encoder
  defstruct [:url,
             :proxy_url,
             :height,
             :width]

end
