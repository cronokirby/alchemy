defmodule Alchemy.Discord.Events do
  alias Alchemy.DMChannel
  @moduledoc false
  # Used to generate events, and notify the main GenEvent

  defp to_struct(kind, attrs) do
      struct = struct(kind)
      Enum.reduce Map.to_list(struct), struct, fn {k, _}, acc ->
        case Map.fetch(attrs, Atom.to_string(k)) do
          {:ok, v} -> %{acc | k => v}
          :error -> acc
        end
      end
    end


  # A direct message was started with the bot
  def handle("CHANNEL_CREATE", %{"is_private" => true} = payload) do
    struct = to_struct(DMChannel, payload)
    GenEvent.notify(Events, {:dm_channel_create, struct})
  end
  def handle("CHANNEL_CREATE", payload) do
    struct = to_struct(DMChannel, payload)
    GenEvent.notify(Events, {:dm_channel_create, struct})
  end

end
