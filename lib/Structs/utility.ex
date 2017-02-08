defmodule Alchemy.Structs.Utility do
  @moduledoc false
  # Contains useful functions for working on Structs

  # Converts a map into a struct, handling string to atom conversion
  def to_struct(kind, attrs) do
      struct = struct(kind)
      Enum.reduce Map.to_list(struct), struct, fn {k, _}, acc ->
        case Map.fetch(attrs, Atom.to_string(k)) do
          {:ok, v} -> %{acc | k => v}
          :error -> acc
        end
      end
    end
end
