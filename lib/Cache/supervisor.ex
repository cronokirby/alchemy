defmodule Alchemy.Cache.Supervisor do
  @moduledoc false
  # This acts as the interface for the Cache. This module acts a GenServer,
  # with internal supervisors used to dynamically start small caches.
  # There are 4 major sections:
  # User; a GenServer keeping track of the state of the client.
  # Channels; a registry between channel ids, and the guild processes they belong to.
  # Guilds; A Supervisor spawning GenServers to keep the state of each guild,
  # as well as a GenServer keeping a registry of these children.
  # PrivateChannels; A Supervisor / GenServer combo, like Guilds, but with less info
  # stored.
  alias Alchemy.Cache.{Guilds, Guilds.GuildSupervisor,
                       PrivChannels,
                       User, Channels}
  use Supervisor



  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = [
      supervisor(Registry, [:unique, :guilds], id: 1),
      supervisor(GuildSupervisor, []),
      worker(PrivChannels, []),
      worker(User, []),
      worker(Channels, [])
    ]

    supervise(children, strategy: :one_for_one)
  end


  # used to handle the READY event
  def ready(user, priv_channels, guilds) do
    Enum.each(guilds, &Task.start(fn ->
      Guilds.add_guild(&1)
    end))
    Enum.each(priv_channels, &Task.start(fn ->
      PrivChannels.add_channel(&1)
    end))
    User.set_user(user)
  end

end
