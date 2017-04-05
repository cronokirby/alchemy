defmodule Alchemy.Cogs.EventRegistry do
  @moduledoc false # Serves as a registry for processes wanting
  # to subscribe to events. The dispatch will then be used to allow
  # for dynamic hooking into events.

  def start_link do
    Registry.start_link(:duplicate, __MODULE__, [])
  end


  def subscribe do
    # the calling process will be sent in
    Registry.register(__MODULE__, :subscribed, nil)
  end


  def dispatch(event) do
    Registry.dispatch(__MODULE__, :subscribed, fn entries ->
      Enum.each(entries, fn {pid, _} -> send(pid, {:discord_event, event}) end)
    end)
  end
end
