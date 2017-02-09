defmodule Alchemy.Discord.StateManager do
  use GenServer
  @moduledoc false
  # A Genserver used to keep track of the State of the client.
  # The state_event handler will pipe info to this module, and the Client can
  # Then access it.
  defmodule State do
    defstruct [:user, guilds: %{}, private_channels: %{}]
  end


  defp cast(msg), do: GenServer.cast(ClientState, msg)
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
    cast {:init, state}
  end

  defp change_object(section, call, object) do
    cast {call, object, section, object["id"]}
  end

  def exists(section, object) do
    cast {:exists?, section, object["id"]}
  end
  ### Private Channels ###

  defp change_priv_channel(call, chan) do
    change_object(:private_channels, call, chan)
  end

  def add_priv_channel(channel), do: change_priv_channel(:store, channel)

  def update_priv_channel(channel), do: change_priv_channel(:merge, channel)

  def rem_priv_channel(chan_id) do
    cast {:remove, :private_channels, chan_id}
  end


  ### Guilds ###

  defp change_guild(call, guild) do
    change_object(:guilds, call, guild)
  end

  # Responsible for creating a global event if the guild is new
  def add_guild(guild) do
    unless exists(:guilds, guild) do
      GenEvent.notify(Events, {:join_guild, guild})
      change_guild(:store, guild)
    end
      change_guild(:merge, guild)
  end



  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, %State{}, opts)
  end

  # Checks if an object exists; used for events that mask both creating and updating
  def handle_call({:exists?, section, key}, _from, state) do
    {:reply,
     Map.get(state, section) |> Map.has_key?(key),
     state}
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
  # Replaces a specific object with a new one
  def handle_cast({:merge, new, section, key}, state) do
     {:noreply,
      Map.get_and_update(state, section, fn sect ->
        Map.get_and_update(sect, key, fn old ->
          Map.merge(old, new)
        end)
      end)}
  end
  # Removes a specifc object
  def handle_cast({:remove, section, key}, state) do
    {:noreply,
     Map.get_and_update(state, section, &(Map.pop(&1, key)))
    }
  end
  # Indexes a new object in a certain section
  def handle_cast({:store, object, section, key}, state) do
    {:noreply, Map.get_and_update(state, section, &(Map.put(&1, key, object)))}
  end
end
