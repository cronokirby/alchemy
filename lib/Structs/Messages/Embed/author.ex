defmodule Alchemy.Embed.Author do
  @moduledoc """
  """
  @type t :: %__MODULE__{
    name: String.t,
    url: String.t,
    icon_url: String.t,
    proxy_icon_url: String.t
  }
  @derive Poison.Encoder
  defstruct [:name,
             :url,
             :icon_url,
             :proxy_icon_url]
end
