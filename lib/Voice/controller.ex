defmodule Alchemy.Voice.Controller do
  use GenServer
  require Logger
  alias Alchemy.Voice.Supervisor.Registry

  defmodule State do
    defstruct [:udp, :ip, :port, :guild_id]
  end

  def start_link(guild_id, udp, ip, port) do
    state = %State{udp: udp, ip: ip, port: port, guild_id: guild_id}
    GenServer.start_link(__MODULE__, state,
                         name: Registry.via({guild_id, :controller}))
  end

  def init(state) do
    Logger.debug "Voice Controller for #{state.guild_id} started"
    {:ok, state}
  end
end
