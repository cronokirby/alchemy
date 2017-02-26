defmodule Alchemy.Cache.Manager do
  @moduledoc false
  # A Genserver used to keep track of the State of the client.
  # The state_event handler will pipe info to this module, and the Client can
  # then access it.
  use GenServer
  alias Alchemy.Guild
  import Alchemy.Cogs.EventHandler, only: [notify: 1]


  defp cast(msg), do: GenServer.cast(ClientState, msg)


  def exists(section, object) do
    GenServer.call ClientState, {:exists?, section, object["id"]}
  end


  # Takes a list of maps, and returns a new map with the "id" of each map pointing
  # to the original
  # [%{"id" => 1, "f" => :foo}, %{"id" = 2, "f" => :foo}] => %{1 => ..., 2 =>}
  def index(map_list, key \\ ["id"]) do
    Enum.into(map_list, %{}, &({get_in(&1, key), &1}))
  end


  # Used to apply `index` to multiple nested fields in a struct
  defp inner_index(base, inners) do
    List.foldr inners, base, fn {field, path}, acc ->
      update_in(acc, field, &index(&1, path))
    end
  end


  # Used to respond to the ready event, and load a lot of data
  # Acts as the "init" of the cache, in a sense
  def ready(user, priv_channels, guilds) do
    state = %{user: user,
              private_channels: index(priv_channels),
              guilds: index(guilds),
              channels: %{}}
    cast {:init, state}
  end


  ### Private Channels ###

  def add_priv_channel(channel) do
    cast {:store, [:private_channels], channel, channel["id"]}
  end


  def update_priv_channel(channel) do
     cast {:merge, [:private_channels, channel["id"]], channel}
  end


  def rem_priv_channel(channel_id) do
    cast {:remove, [:private_channels], channel_id}
  end


  ### Guilds ###

  # like index, but will also index the members
  defp guild_index(guild) do
    inners = [
      {["members"], ["user", "id"]},
      {["roles"], ["id"]},
      {["presences"], ["user", "id"]},
      {["voice_states"], ["user_id"]}
    ]
    inner_index(guild, inners)
  end


  # Creates a new map with every channel pointing to its guild
  defp channel_index(channels, guild_id) do
    Enum.into(channels, %{}, &({get_in(&1, ["id"]), guild_id}))
  end


  # Responsible for creating a global event if the guild is new
  def add_guild(guild) do
    if exists([:guilds], guild) do
      update_guild(guild)
    else
      notify {:join_guild, [Guild.from_map(guild)]}
      guild_id = guild["id"]
      cast {:store, [:guilds], guild_index(guild), guild_id}
      cast {:merge, [:channels], channel_index(guild["channels"], guild_id)}
    end
  end


  def remove_guild(guild) do
    cast {:remove, [:guilds], guild["id"]}
  end


  def update_guild(guild) do
    indexed = guild_index(guild)
    guild_id = guild["id"]
    cast {:merge, [:guilds, guild_id], indexed}
    cast {:merge, [:channels], channel_index(guild["channels"], guild_id)}
  end


  # "unavaliable" indicates an old guild going offline, in which case we don't
  # want to remove that guild entirely.
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
    cast {:replace, [:guilds, guild_id, "members", id], member}
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


  ### Presences ###

  def update_presence(presence) do
    guild_id = presence["guild_id"]
    pres_id = presence["user"]["id"]
    cast {:merge, [:guilds, guild_id, "presences", pres_id], presence}
  end


  ### Voice States ###

  def update_voice_state(%{"user_id" => id, "guild_id" => guild_id} = voice) do
    cast {:merge, [:guilds, guild_id, "voice_states", id], voice}
  end


  ### Server ###

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, %{}, opts)
  end


  # Checks if an object exists; used for events that mask both creating and updating
  def handle_call({:exists?, section, key}, _from, state) do
    {:reply,
     state |> get_in(section) |> Map.has_key?(key),
     state}
  end


  def handle_call(_, _from, state) do
    {:reply, state, state}
  end


  def handle_cast({:init, state}, %{}) do
    {:noreply, state}
  end


  def handle_cast({:init, new}, old) do
    private_channels = new.private_channels
    guilds = new.guilds
    {:noreply,
     old
     |> update_in([:guilds], &Map.merge(&1, guilds))
     |> update_in([:private_channels], &Map.merge(&1, private_channels))}
  end


  defmacrop safe_access(normal) do
    quote do
      case get_in(var!(state), var!(section)) do
        nil ->
          {:noreply, var!(state)}
        _ ->
          unquote(normal)
      end
    end
  end


  # Replaces a specific node with a new one
  def handle_cast({:merge, section, new}, state) do
    safe_access(
      {:noreply, update_in(state, section, &Map.merge(&1, new))}
    )
  end


  # Replaces a leaf with a new value
  def handle_cast({:replace, section, new}, state) do
    safe_access(
      {:noreply, put_in(state, section, new)}
    )
  end


  # Removes a specific object from a node
  def handle_cast({:remove, section, key}, state) do
    safe_access(
      {:noreply, update_in(state, section, &Map.delete(&1, key))}
    )
  end


  # Indexes a new object in a certain section
  def handle_cast({:store, section, object, key}, state) do
    safe_access(
      {:noreply, update_in(state, section, &Map.put(&1, key, object))}
    )
  end

end
