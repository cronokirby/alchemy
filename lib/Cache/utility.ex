defmodule Alchemy.Cache.Utility do
  # contains useful functions for working with maps
  @moduledoc false

  # Takes a list of maps, and returns a new map with the "id" of each map pointing
  # to the original
  # [%{"id" => 1, "f" => :foo}, %{"id" = 2, "f" => :foo}] => %{1 => ..., 2 =>}
  def index(map_list, key \\ ["id"]) do
    Enum.into(map_list, %{}, &{get_in(&1, key), &1})
  end

  # Used to apply `index` to multiple nested fields in a struct
  def inner_index(base, inners) do
    List.foldr(inners, base, fn {field, path}, acc ->
      update_in(acc, field, &index(&1, path))
    end)
  end

  # this will check for null keys
  def safe_inner_index(base, inners) do
    List.foldr(inners, base, fn {field, path}, acc ->
      case get_in(acc, field) do
        nil -> acc
        _ -> update_in(acc, field, &index(&1, path))
      end
    end)
  end
end
