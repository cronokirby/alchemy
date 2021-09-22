defmodule Alchemy.Guild.Emoji do
  @moduledoc false

  @derive Poison.Encoder
  defstruct [:id, :name, :roles, :require_colons, :managed, :animated, :available]

  defimpl String.Chars, for: __MODULE__ do
    def to_string(emoji) do
      if emoji.animated do
        "<a:#{emoji.name}:#{emoji.id}>"
      else
        "<:#{emoji.name}:#{emoji.id}>"
      end
    end
  end
end
