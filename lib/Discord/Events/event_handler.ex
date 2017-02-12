defmodule Alchemy.Discord.EventHandler do
  use GenServer
  @moduledoc false
  # A Generic event handler, who's behaviour is specified when it's started
  def start_link(name, event_type, module, method) do
    state = %{event_type: event_type, module: module, method: method}
    GenServer.start_link(__MODULE__, state, name: name)
  end

  # If the event is of the same type, it calls the stored message
  def handle_cast({event_type, args}, state) do
    ev = state.event_type
    case event_type do
      ^ev ->
        apply(state.module, state.method, args)
      _ -> nil
    end
    {:noreply, state}
  end
end
