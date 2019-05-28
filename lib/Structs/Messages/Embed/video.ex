defmodule Alchemy.Embed.Video do
  @moduledoc false

  @derive Poison.Encoder
  defstruct [:url, :height, :width]
end
