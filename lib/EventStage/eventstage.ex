defmodule Alchemy.EventStage.EventStage do
  # Serves as the 2nd part of the 3rd stage
  @moduledoc false
  # Takes the events, and finds out which handler functions to call,
  # before sending them down to the last stage.
  use GenStage
  alias Alchemy.EventStage.Cacher
  alias Alchemy.Cogs.EventHandler

  def start_link(limit) do
    GenStage.start_link(__MODULE__, limit, name: __MODULE__)
  end

  def init(limit) do
    producers = for x <- 1..limit, do: Module.concat(Cacher, :"#{x}")
    {:producer_consumer, :ok, subscribe_to: producers}
  end

  def handle_events(events, _from, state) do
    found = EventHandler.find_handles(events)
    {:noreply, found, state}
  end
end
