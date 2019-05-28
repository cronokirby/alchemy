defmodule Alchemy.Attachment do
  # documented in Alchemy.Embed
  @moduledoc false

  @derive Poison.Encoder
  defstruct [:id, :filename, :size, :url, :proxy_url, :height, :width]
end
