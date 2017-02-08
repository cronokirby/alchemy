defmodule Alchemy.Discord.StateManager do
  use GenServer
  @moduledoc false
  # A Genserver used to keep track of the State of the client.
  # The state_event handler will pipe info to this module, and the Client can
  # Then access it.
  defmodule State do
    defstruct [:user, guilds: %{}, private_channels: %{}]
  end



  # Takes a list of maps, and returns a new map with the "id" of each map pointing
  # to the original
  # [%{"id" => 1, "f" => :foo}, %{"id" = 2, "f" => :foo}] => %{1 => ..., 2 =>}
  defp index(map_list) do
    Enum.into(map_list, %{}, &({&1["id"], &1}))
  end

  def ready(user, priv_channels, guilds) do
   state = %State{user: user,
                  private_channels: index(priv_channels),
                  guilds: index(guilds)}
   GenServer.cast(ClientState, {:init, state})
  end

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, %State{}, opts)
  end

  def handle_call(_, _from, state) do
    {:reply, state, state}
  end

  def handle_cast({:init, state}, _) do
    {:noreply, state}
  end
  # Completely replaces a section, useful for initialisation
  def handle_cast({:swap, new, section}, state) do
    {:noreply, Map.put(state, section, new)}
  end
  # Indexes a new object in a certain section
  def handle_cast({:store, object, section, key}, state) do
    {:noreply, Map.get_and_update(state, section, &(Map.put(&1, key, object)))}
  end
end
