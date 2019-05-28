defmodule Alchemy.EventStage.EventDispatcher do
  # Serves as a small consumer of the 3rd stage,
  @moduledoc false
  # forwarding events to notify processes subscribed in the EventRegistry
  use GenStage
  alias Alchemy.Cogs.EventRegistry
  alias Alchemy.EventStage.Cacher

  def start_link(limit) do
    GenStage.start_link(__MODULE__, limit)
  end

  def init(limit) do
    producers = for x <- 1..limit, do: Module.concat(Cacher, :"#{x}")
    {:consumer, :ok, subscribe_to: producers}
  end

  def handle_events(events, _from, state) do
    EventRegistry.dispatch(events)
    {:noreply, [], state}
  end
end
