defmodule Alchemy.Attachment do
  @moduledoc false # documented in Alchemy.Embed


  @derive Poison.Encoder
  defstruct [:id,
             :filename,
             :size,
             :url,
             :proxy_url,
             :height,
             :width]
end
