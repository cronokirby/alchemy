defmodule Alchemy.Embed.Footer do
  @moduledoc false

  @derive Poison.Encoder
  defstruct [:text, :icon_url, :proxy_icon_url]
end
