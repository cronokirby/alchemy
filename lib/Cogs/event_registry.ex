defmodule Alchemy.Cogs.EventRegistry do
  # Serves as a registry for processes wanting
  @moduledoc false
  # to subscribe to events. The dispatch will then be used to allow
  # for dynamic hooking into events.

  def start_link do
    Registry.start_link(keys: :duplicate, name: __MODULE__)
  end

  def subscribe do
    # the calling process will be sent in
    Registry.register(__MODULE__, :subscribed, nil)
  end

  def dispatch(events) do
    Registry.dispatch(__MODULE__, :subscribed, fn entries ->
      Enum.each(entries, fn {pid, _} ->
        Enum.each(events, &send(pid, {:discord_event, &1}))
      end)
    end)
  end
end
