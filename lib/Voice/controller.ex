defmodule Alchemy.Voice.Controller do
  use GenServer
  require Logger
  alias Alchemy.Voice.Supervisor.VoiceRegistry

  defmodule State do
    defstruct [:udp, :ip, :port, :guild_id]
  end

  def start_link(udp, ip, port, guild_id) do
    state = %State{udp: udp, ip: ip, port: port, guild_id: guild_id}
    GenServer.start_link(__MODULE__, state,
                         name: VoiceRegistry.via({guild_id, :controller}))
  end

  def init(state) do
    Logger.debug "Voice Controller for #{state.guild_id} started"
    {:ok, state}
  end
end
