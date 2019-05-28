defmodule Alchemy.Structs do
  @moduledoc false
  # Contains useful functions for working on the Structs in this library

  # Converts a map into a struct, handling string to atom conversion
  def to_struct(attrs, kind) do
    struct = struct(kind)

    Enum.reduce(Map.to_list(struct), struct, fn {k, _}, acc ->
      case Map.fetch(attrs, Atom.to_string(k)) do
        {:ok, v} -> %{acc | k => v}
        :error -> acc
      end
    end)
  end

  # Maps struct conversion over an enum
  def map_struct(nil, _), do: nil

  def map_struct(list, kind) do
    Enum.map(list, &to_struct(&1, kind))
  end

  def field(map, key, kind) do
    update_in(map[key], &to_struct(&1, kind))
  end

  def field?(map, key, kind) do
    case map[key] do
      nil -> map
      _ -> update_in(map[key], &to_struct(&1, kind))
    end
  end

  def field_map(map, key, func) do
    update_in(map[key], &func.(&1))
  end

  def field_map?(map, key, func) do
    case map[key] do
      nil -> map
      _ -> update_in(map, [key], &func.(&1))
    end
  end

  def fields_from_map(map, key, module) do
    field_map(map, key, &Enum.map(&1, fn x -> module.from_map(x) end))
  end

  def fields_from_map?(map, key, module) do
    case map[key] do
      nil -> map
      _ -> fields_from_map(map, key, module)
    end
  end
end
