defmodule Alchemy.Embed.Thumbnail do
  @moduledoc false

  @derive Poison.Encoder
  defstruct [:url, :proxy_url, :height, :width]
end
