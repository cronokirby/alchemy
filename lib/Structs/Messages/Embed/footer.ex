defmodule Alchemy.Embed.Footer do
  @moduledoc """
  """
  @type t :: %__MODULE__{
    text: String.t,
    icon_url: String.t,
    proxy_icon_url: String.t
  }
  @derive Poison.Encoder
  defstruct [:text,
             :icon_url,
             :proxy_icon_url]
end
