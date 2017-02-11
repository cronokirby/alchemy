defmodule Alchemy.Attachment do
  @moduledoc """
  """
  @type t :: %__MODULE__{
    id: String.t,
    filename: String.t,
    size: Integer,
    url: String.t,
    proxy_url: String.t,
    height: Integer | nil,
    width: Integer | nil
  }
  @derive Poison.Encoder
  defstruct [:id,
             :filename,
             :size,
             :url,
             :proxy_url,
             :height,
             :width]
end
