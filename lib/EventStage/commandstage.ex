defmodule Alchemy.EventStage.CommandStage do
  # One of the 2 parts of the third stage of the pipeline
  @moduledoc false
  # This serves to figure out which message create events
  # contain a command needing to be run, and then send those forward
  # to the final stage
  use GenStage
  alias Alchemy.EventStage.Cacher
  alias Alchemy.Cogs.CommandHandler

  def start_link(limit) do
    GenStage.start_link(__MODULE__, limit, name: __MODULE__)
  end

  def init(limit) do
    selector = fn {event, _args} -> event == :message_create end

    producers =
      for x <- 1..limit do
        {Module.concat(Cacher, :"#{x}"), selector: selector}
      end

    {:producer_consumer, :ok, subscribe_to: producers}
  end

  def handle_events(events, _from, state) do
    # most message creates get filtered out here
    found = CommandHandler.find_commands(events)
    {:noreply, found, state}
  end
end
