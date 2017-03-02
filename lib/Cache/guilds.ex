defmodule Alchemy.Cache.Guilds do
  @moduledoc false # The template GenServer for guilds started dynamically
  # by the supervisor in the submodule below
  use GenServer
  alias Alchemy.Cache.Guilds.GuildSupervisor
  alias Alchemy.Cache.Channels
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


  defp call(id, msg) do
    GenServer.call(via_guilds(id), msg)
  end


  def start_link(%{"id" => id} = guild) do
    GenServer.start_link(__MODULE__, guild, name: via_guilds(id))
  end


  # This changes the inner arrays to become maps, for easier access later
  defp guild_index(%{"unavailable" => true} = guild) do
    guild
  end
  defp guild_index(guild) do
    inners = [
      {["members"], ["user", "id"]},
      {["roles"], ["id"]},
      {["presences"], ["user", "id"]},
      {["voice_states"], ["user_id"]},
      {["emojis"], ["id"]}
    ]
    inner_index(guild, inners)
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
      [{pid, _}] ->
        GenServer.call(pid, {:merge, guild_index(guild)})
    end

  end


  def remove_guild(%{"id" => id, "unavailable" => true} = guild) do
    call(id, :set_unavailable)
  end
  def remove_guild(%{"id" => id}) do
    Supervisor.terminate_child(GuildSupervisor, via_guilds(id))
  end


  def update_guild(%{"id" => id} = guild) do
    Channels.add_channels(guild["channels"], id)
    call(id, {:merge, guild_index(guild)})
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

  def handle_call({:merge, new_info}, _, state) do
    {:reply, :ok, Map.merge(state, new_info)}
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
