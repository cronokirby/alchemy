defmodule Alchemy.Cache.Guilds do
  # The template GenServer for guilds started dynamically
  @moduledoc false
  # by the supervisor in the submodule below
  use GenServer
  alias Alchemy.Cache.Guilds.GuildSupervisor
  alias Alchemy.Cache.Channels
  alias Alchemy.Guild
  import Alchemy.Cache.Utility

  defmodule GuildSupervisor do
    @moduledoc false
    # acts as a dynamic supervisor for the surrounding GenServer
    use Supervisor
    alias Alchemy.Cache.Guilds

    def start_link do
      Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
    end

    def init(:ok) do
      children = [
        worker(Guilds, [])
      ]

      supervise(children, strategy: :simple_one_for_one)
    end
  end

  defp via_guilds(id) do
    {:via, Registry, {:guilds, id}}
  end

  def safe_call(id, msg) do
    if Registry.lookup(:guilds, id) != [] do
      {:ok, call(id, msg)}
    else
      {:error, :no_guild}
    end
  end

  def call(id, msg) do
    GenServer.call(via_guilds(id), msg)
  end

  def start_link(%{"id" => id} = guild) do
    GenServer.start_link(__MODULE__, guild, name: via_guilds(id))
  end

  @guild_indexes [
    {["members"], ["user", "id"]},
    {["roles"], ["id"]},
    {["presences"], ["user", "id"]},
    {["voice_states"], ["user_id"]},
    {["emojis"], ["id"]},
    {["channels"], ["id"]}
  ]
  # This changes the inner arrays to become maps, for easier access later
  defp guild_index(%{"unavailable" => true} = guild) do
    guild
  end

  defp guild_index(guild) do
    inner_index(guild, @guild_indexes)
  end

  # This version will check for null keys. Useful in the update event
  defp safe_guild_index(guild) do
    safe_inner_index(guild, @guild_indexes)
  end

  def de_index(guild) do
    keys = ["members", "roles", "presences", "voice_states", "emojis", "channels"]

    Enum.reduce(keys, guild, fn k, g ->
      update_in(g[k], &Map.values/1)
    end)
  end

  defp start_guild(guild) do
    Supervisor.start_child(GuildSupervisor, [guild])
    {:unavailable_guild, []}
  end

  # The guild is either new, or partial info for an existing guild
  def add_guild(%{"unavailable" => true} = guild) do
    start_guild(guild)
  end

  def add_guild(%{"id" => id} = guild) do
    Channels.add_channels(guild["channels"], id)

    case Registry.lookup(:guilds, id) do
      [] ->
        start_guild(guild_index(guild))
        {:guild_create, [Guild.from_map(guild)]}

      [{pid, _}] ->
        GenServer.call(pid, {:merge, guild_index(guild)})
        {:guild_online, [Guild.from_map(guild)]}
    end
  end

  def remove_guild(%{"id" => id, "unavailable" => true}) do
    call(id, :set_unavailable)
  end

  def remove_guild(%{"id" => id}) do
    Supervisor.terminate_child(GuildSupervisor, via_guilds(id))
    {:guild_delete, [id]}
  end

  # Because this event is usually partial, we use safe_guild_index
  def update_guild(%{"id" => id} = guild) do
    Channels.add_channels(guild["channels"], id)
    call(id, {:merge, safe_guild_index(guild)})
  end

  def update_emojis(%{"guild_id" => id, "emojis" => emojis}) do
    call(id, {:replace, "emojis", index(emojis)})
  end

  def update_member(guild_id, %{"user" => %{"id" => id}} = member) do
    call(guild_id, {:update, ["members", id], member})
  end

  def remove_member(guild_id, %{"id" => id}) do
    call(guild_id, {:pop, "members", id})
  end

  def add_role(guild_id, %{"id" => id} = role) do
    call(guild_id, {:put, "roles", id, role})
  end

  def update_role(guild_id, role) do
    add_role(guild_id, role)
  end

  def remove_role(guild_id, role_id) do
    call(guild_id, {:pop, "roles", role_id})
  end

  def add_channel(guild_id, %{"id" => id} = channel) do
    Channels.add_channels([channel], channel["guild_id"]) # assume has guild_id, otherwise we have no idea where it belongs
    call(guild_id, {:put, "channels", id, channel})
  end

  def update_channel(guild_id, channel) do
    add_channel(guild_id, channel)
  end

  def remove_channel(guild_id, channel_id) do
    Channels.remove_channel(channel_id)
    call(guild_id, {:pop, "channels", channel_id})
  end

  def update_presence(presence) do
    guild_id = presence["guild_id"]
    pres_id = presence["user"]["id"]
    call(guild_id, {:update_presence, pres_id, presence})
  end

  def update_voice_state(%{"user_id" => id, "guild_id" => guild_id} = voice) do
    call(guild_id, {:put, "voice_states", id, voice})
  end

  def add_members(guild_id, members) do
    call(guild_id, {:update, ["members"], index(members, ["user", "id"])})
  end

  ### Server ###

  # This call returns the full info, because the partial info from the event
  # isn't usually very useful.
  def handle_call({:merge, new_info}, _, state) do
    new = Map.merge(state, new_info)
    {:reply, new, new}
  end

  def handle_call(:show, _, state) do
    {:reply, state, state}
  end

  def handle_call({:section, key}, _, state) do
    {:reply, state[key], state}
  end

  # as opposed to the above call, this also returns the id of the guild
  def handle_call({:section_with_id, key}, _, state) do
    {:reply, {state["id"], state[key]}, state}
  end

  def handle_call(_, _, %{"unavailable" => true} = state) do
    {:reply, :ok, state}
  end

  def handle_call({:replace, section, data}, _, state) do
    {:reply, :ok, %{state | section => data}}
  end

  def handle_call({:put, section, key, node}, _, state) do
    {:reply, :ok, put_in(state, [section, key], node)}
  end

  def handle_call({:update, section, data}, _, state) do
    new =
      update_in(state, section, fn
        # Need to figure out why members sometimes become nil.
        nil -> data
        there -> Map.merge(there, data)
      end)

    {:reply, :ok, new}
  end

  # this event is special enough to warrant its own special handling
  def handle_call({:update_presence, key, data}, _, state) do
    new =
      if Map.has_key?(state["presences"], key) do
        update_in(state, ["presences", key], fn presence ->
          case {data, presence} do
            {%{"user" => new}, %{"user" => old}} ->
              new_user = Map.merge(new, old)

              presence
              |> Map.merge(data)
              |> Map.put("user", new_user)

            _ ->
              Map.merge(presence, data)
          end
        end)
      else
        put_in(state, ["presences", key], data)
      end

    {:reply, :ok, new}
  end

  def handle_call({:pop, section, key}, _, state) do
    {_, new} = pop_in(state, [section, key])
    {:reply, :ok, new}
  end

  def handle_call(:set_unavailable, _, guild) do
    {:reply, :ok, %{guild | "unavailable" => true}}
  end
end
