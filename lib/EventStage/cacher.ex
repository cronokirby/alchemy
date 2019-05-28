defmodule Alchemy.EventStage.Cacher do
  # This stage serves to update the cache
  @moduledoc false
  # before passing events on.
  # To leverage the concurrent cache, this module
  # is intended to be duplicated for each scheduler.
  # After that, it broadcasts split over the command and event dispatcher
  use GenStage
  alias Alchemy.EventStage.EventBuffer
  alias Alchemy.Discord.Events

  # Each of the instances gets a specific id
  def start_link(id) do
    name = Module.concat(__MODULE__, :"#{id}")
    GenStage.start_link(__MODULE__, :ok, name: name)
  end

  def init(:ok) do
    # no state to keep track of, subscribe to the event source
    {:producer_consumer, :ok,
     [subscribe_to: [EventBuffer], dispatcher: GenStage.BroadcastDispatcher]}
  end

  def handle_events(events, _from, state) do
    # I think that using async_stream here would be redundant,
    # as we're already duplicating this stage. This might warrant future
    # testing, and would be an easy change to implement
    cached =
      Enum.map(events, fn {type, payload} ->
        Events.handle(type, payload)
      end)

    {:noreply, cached, state}
  end
end
