defmodule Alchemy.EventStage.EventBuffer do
  # This is the entry point for the event pipeline
  @moduledoc false
  # The websockets notify this module of events, and this
  # stage buffers them until the handlers are ready.
  use GenStage

  def start_link do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  # Asyncronous, as it's imperative the WS doesn't get blocked.
  def notify(event) do
    GenStage.cast(__MODULE__, {:notify, event})
  end

  def init(:ok) do
    {:producer, {:queue.new(), 0}}
  end

  def handle_cast({:notify, event}, {queue, demand}) do
    queue = :queue.in(event, queue)
    dispatch(queue, demand, [])
  end

  def handle_demand(incoming, {queue, pending}) do
    dispatch(queue, incoming + pending, [])
  end

  # This is the escape clause for the lower case,
  # but also the case that gets matched when there's no demand
  def dispatch(queue, 0, events) do
    {:noreply, Enum.reverse(events), {queue, 0}}
  end

  def dispatch(queue, demand, events) do
    # This recursion will end in 2 ways:
    # events < demand: we end up here, reverse events
    # because we were prepending them; and then dispatch
    # events > demand: the upper clause gets matched
    case :queue.out(queue) do
      {{:value, event}, queue} ->
        dispatch(queue, demand - 1, [event | events])

      {:empty, queue} ->
        {:noreply, Enum.reverse(events), {queue, demand}}
    end
  end
end
