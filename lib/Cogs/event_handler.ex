defmodule Alchemy.Cogs.EventHandler do
  @moduledoc false
  # This server will recieve casts from the gateway, and decide which functions
  # to call to handle those casts.
  # This server is intended to be unique.
  use GenServer
  alias Alchemy.Cogs.EventRegistry


  # Starts up a task for handle registered for that event
  def notify(msg) do
    GenServer.cast(__MODULE__, {:notify, msg})
  end


  def disable(module, function) do
    GenServer.call(__MODULE__, {:disable, module, function})
  end


  def unload(module) do
    GenServer.call(__MODULE__, {:unload, module})
  end

  # Used at the beginning of the application to add said handles
  def add_handler(handle) do
    GenServer.cast(__MODULE__, {:add_handle, handle})
  end


  ### Server ###

  def start_link do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end


  def handle_call({:disable, module, function}, _from, state) do
    new = Enum.map(state, fn {k, v} ->
      {k, Enum.filter(v, &!match?({^module, ^function}, &1))}
    end) |> Enum.into(%{})
    {:reply, :ok, new}
  end


  def handle_call({:unload, module}, _from, state) do
    new = Enum.map(state, fn {k, v} ->
      {k, Enum.filter(v, &!match?({^module, _}, &1))}
    end) |> Enum.into(%{})
    {:reply, :ok, new}
  end

  # Adds a new handler to the map, indexed by type
  def handle_cast({:add_handle, {type, handle}}, state) do
    {:noreply,
     update_in(state[type], fn maybe ->
       case maybe do
         nil -> [handle]  # nil because the type doesn't have a func yet
         val -> [handle | val]
       end
     end)}
  end


  def handle_cast({:notify, {type, args}}, state) do
    Enum.each(Map.get(state, type, []), fn {m, f} ->
      Task.start(fn -> apply(m, f, args) end)
    end)
    EventRegistry.dispatch({type, args})
    {:noreply, state}
  end

end
