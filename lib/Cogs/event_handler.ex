defmodule Alchemy.Cogs.EventHandler do
  # This server keeps tracks of the various handler
  @moduledoc false
  # functions subscribed to different events. The EventStage uses
  # this server to figure out how to dispatch commands
  use GenServer

  def disable(module, function) do
    GenServer.call(__MODULE__, {:disable, module, function})
  end

  def unload(module) do
    GenServer.call(__MODULE__, {:unload, module})
  end

  # Used at the beginning of the application to add said handles
  def add_handler(handle) do
    GenServer.call(__MODULE__, {:add_handle, handle})
  end

  def find_handles(events) do
    state = GenServer.call(__MODULE__, :copy)

    Enum.flat_map(events, fn {type, args} ->
      case state[type] do
        nil ->
          []

        handles ->
          Enum.map(handles, fn {m, f} -> {m, f, args} end)
      end
    end)
  end

  ### Server ###

  def start_link do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def handle_call({:disable, module, function}, _from, state) do
    new =
      Enum.map(state, fn {k, v} ->
        {k, Enum.filter(v, &(!match?({^module, ^function}, &1)))}
      end)
      |> Enum.into(%{})

    {:reply, :ok, new}
  end

  def handle_call({:unload, module}, _from, state) do
    new =
      Enum.map(state, fn {k, v} ->
        {k, Enum.filter(v, &(!match?({^module, _}, &1)))}
      end)
      |> Enum.into(%{})

    {:reply, :ok, new}
  end

  # Adds a new handler to the map, indexed by type
  def handle_call({:add_handle, {type, handle}}, _from, state) do
    {:reply, :ok,
     update_in(state[type], fn maybe ->
       case maybe do
         # nil because the type doesn't have a func yet
         nil -> [handle]
         val -> [handle | val]
       end
     end)}
  end

  def handle_call(:copy, _from, state) do
    {:reply, state, state}
  end
end
