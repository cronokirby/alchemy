defmodule Alchemy.Embed.Provider do
  @moduledoc false

  @derive Poison.Encoder
  defstruct [:name, :url]
end
