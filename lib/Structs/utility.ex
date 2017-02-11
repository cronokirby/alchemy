defmodule Alchemy.Structs.Utility do
  @moduledoc false
  # Contains useful functions for working on Structs

  # Converts a map into a struct, handling string to atom conversion
  def to_struct(attrs, kind) do
      struct = struct(kind)
      Enum.reduce Map.to_list(struct), struct, fn {k, _}, acc ->
        case Map.fetch(attrs, Atom.to_string(k)) do
          {:ok, v} -> %{acc | k => v}
          :error -> acc
        end
      end
  end

  # Maps struct conversion over an enum
  def map_struct(list, kind) do
    Enum.map list, &(to_struct(&1, kind))
  end

  def field(map, key, kind) do
     Map.get_and_update(map, key, &(to_struct(&1, kind)))
  end
  def field_map(map, key, func) do
    Map.get_and_update(map, key, &(func.(&1)))
  end
end
