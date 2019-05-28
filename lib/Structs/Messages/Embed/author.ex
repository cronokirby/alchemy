defmodule Alchemy.Embed.Author do
  @moduledoc false

  @derive Poison.Encoder
  defstruct [:name, :url, :icon_url, :proxy_icon_url]
end
