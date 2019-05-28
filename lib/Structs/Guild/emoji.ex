defmodule Alchemy.Guild.Emoji do
  @moduledoc false

  @derive Poison.Encoder
  defstruct [:id, :name, :roles, :require_colons, :managed]

  defimpl String.Chars, for: __MODULE__ do
    def to_string(emoji), do: "<:#{emoji.name}:#{emoji.id}>"
  end
end
