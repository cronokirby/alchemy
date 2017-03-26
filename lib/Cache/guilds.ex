defmodule Alchemy.Cache.Guilds do
  @moduledoc false # The template GenServer for guilds started dynamically
  # by the supervisor in the submodule below
  use GenServer
  alias Alchemy.Cache.Guilds.GuildSupervisor
  alias Alchemy.Cache.Channels
  alias Alchemy.Guild
  import Alchemy.Cache.Utility
  import Alchemy.Cogs.EventHandler, only: [notify: 1]

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
    Supervisor.start_child(GuildSupervisor, [guild_index(guild)])
  end


  # The guild is either new, or partial info for an existing guild
  def add_guild(%{"id" => id} = guild) do
    Channels.add_channels(guild["channels"], id)
    case Registry.lookup(:guilds, id) do
      [] ->
        start_guild(guild)
        notify {:guild_create, [Guild.from_map(guild)]}
      [{pid, _}] ->
        guild = GenServer.call(pid, {:merge, guild_index(guild)})
        notify {:guild_online, [Guild.from_map(guild)]}
    end
  end


  def remove_guild(%{"id" => id, "unavailable" => true} = guild) do
    call(id, :set_unavailable)
  end
  def remove_guild(%{"id" => id}) do
    Supervisor.terminate_child(GuildSupervisor, via_guilds(id))
    notify {:guild_delete, [id]}
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
    call(guild_id, {:put, "members", id, member})
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


  def update_presence(presence) do
    guild_id = presence["guild_id"]
    pres_id = presence["user"]["id"]
    call(guild_id, {:put, "presences", pres_id, presence})
  end


  def update_voice_state(%{"user_id" => id, "guild_id" => guild_id} = voice) do
    call(guild_id, {:put, "voice_states", id, voice})
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


  def handle_call({:replace, section, data}, _, state) do
    {:reply, :ok, %{state | section => data}}
  end


  def handle_call({:put, section, key, node}, _, state) do
    {:reply, :ok, put_in(state, [section, key], node)}
  end


  def handle_call({:pop, section, key}, _, state) do
    {_, new} = pop_in(state, [section, key])
    {:reply, :ok, new}
  end


  def handle_call(:set_unavailable, _, guild) do
    {:reply, :ok, %{guild | "unavailable" => true}}
  end

end
