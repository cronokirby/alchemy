defmodule Alchemy.Discord.StateManager do
  alias Alchemy.Guild
  import Alchemy.Discord.EventManager
  use GenServer
  @moduledoc false
  # A Genserver used to keep track of the State of the client.
  # The state_event handler will pipe info to this module, and the Client can
  # Then access it.

  defp cast(msg), do: GenServer.cast(ClientState, msg)

  def exists(section, object) do
    cast {:exists?, section, object["id"]}
  end

  # Takes a list of maps, and returns a new map with the "id" of each map pointing
  # to the original
  # [%{"id" => 1, "f" => :foo}, %{"id" = 2, "f" => :foo}] => %{1 => ..., 2 =>}
  defp index(map_list, key \\ ["id"]) do
    Enum.into(map_list, %{}, &({get_in(&1, key), &1}))
  end

  defp inner_index(list, inners, base_key \\ ["id"]) do
     shift_keys = fn guild ->
       List.foldr inners, guild, fn {field, path}, acc ->
         update_in acc, field, &(index(&1, path))
       end
     end
     Enum.into(list, %{}, fn base ->
       {get_in(base, base_key), shift_keys.(base)}
     end)
  end

  # like index, but will also index the members
  defp guild_index(guild_list) do
    inners = [
      {"members", ["user", "id"]},
      {"roles", ["id"]}
    ]
    inner_index(guild_list, inners)
  end


  # Used to respond to the ready event, and load a lot of data
  def ready(user, priv_channels, guilds) do
    state = %{user: user,
              private_channels: index(priv_channels),
              guilds: guild_index(guilds)}
    cast {:init, state}
  end


  ### Private Channels ###

  def add_priv_channel(channel) do
    cast {:store, [:private_channels], channel, channel["id"]}
  end

  def update_priv_channel(channel) do
     cast {:merge, [:private_channels, channel["id"]], channel}
  end

  def rem_priv_channel(chan_id) do
    cast {:remove, [:private_channels], chan_id}
  end


  ### Guilds ###

  # Responsible for creating a global event if the guild is new
  def add_guild(guild) do
    if exists(:guilds, guild) do
      update_guild(guild)
    else
      notify {:join_guild, [Guild.from_map(guild)]}
      cast {:store, [:guilds], guild, guild["id"]}
    end
  end

  def remove_guild(guild) do
    cast {:remove, [:guilds], guild["id"]}
  end

  def update_guild(guild) do
    cast {:merge, [:guilds, guild["id"]], guild}
  end
  # 2 cases: the guild is merely unavaliable, in which case you merge that info,
  # or the user was removed from the guild, in which case you send a notify,
  # and remove that object entirely
  def delete(%{"unavailiable" => true} = guild) do
    update_guild(guild)
  end
  def delete(guild) do
    remove_guild(guild)
    notify {:leave_guild, [Guild.from_map(guild)]}
  end

  def update_emojis(%{"guild_id" => id, "emojis" => emojis}) do
    cast {:replace, [:guilds, id, "emojis"], emojis}
  end


  ### Members ###

  def update_member(guild_id, %{"user" => %{"id" => id}} = member) do
    cast {:merge, [:guilds, guild_id, "members", id], member}
  end

  def remove_user(guild_id, %{"id" => id}) do
  cast {:remove, [:guilds, guild_id, "members"], id}
  end


  ### Roles ###

  def add_role(guild_id, %{"id" => id} = role) do
    cast {:store, [:guilds, guild_id, "roles"], role, id}
  end

  def update_role(guild_id, %{"id" => id} = role) do
    cast {:merge, [:guilds, guild_id, "roles", id], role}
  end

  def remove_role(guild_id, role_id) do
    cast {:remove, [:guilds, guild_id, "roles"], role_id}
  end


  ### Server ###

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, %{}, opts)
  end

  # Checks if an object exists; used for events that mask both creating and updating
  def handle_call({:exists?, section, key}, _from, state) do
    {:reply,
     get_in(state, section) |> Map.has_key?(key),
     state}
  end
  def handle_call(_, _from, state) do
    {:reply, state, state}
  end

  def handle_cast({:init, state}, _) do
    {:noreply, state}
  end
  # Replaces a specific node with a new one
  def handle_cast({:merge, new, section}, state) do
     {:noreply,
      update_in(state, section, &(Map.merge(&1, new)))
     }
  end
  # Replaces a leaf with a new value
  def handle_cast({:replace, new, section}, state) do
    {:noreply,
     put_in(state, section, new)
    }
  end
  # Removes a specific object from a node
  def handle_cast({:remove, section, key}, state) do
    {:noreply,
     update_in(state, section, &(Map.pop(&1, key)))
    }
  end
  # Indexes a new object in a certain section
  def handle_cast({:store, object, section, key}, state) do
    {:noreply, update_in(state, section, &(Map.put(&1, key, object)))}
  end
end
