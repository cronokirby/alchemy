defmodule Alchemy.Cache.PrivChannels do
  @moduledoc false # The temple GenServer for private channels
  # dynamically started by the supervisor in the submodule below
  use GenServer
  alias Alchemy.Cache.PrivChanSupervisor
  import Alchemy.Cache.Utility


  defmodule PrivChanSupervisor do
    @moduledoc false
    # acts as a dynamic supervisor for the module above
    use Supervisor
    alias Alchemy.Cache.PrivChannels


    def start_link do
      Supervisor.start_link(__MODULE__, :ok)
    end


    def init(:ok) do
      children = [
        worker(PrivChannels, [])
      ]

      supervise(children, strategy: :simple_one_for_one)
    end
  end


  defp via_priv_channels(id) do
    {:via, Registry, {:priv_channels, id}}
  end


  defp call(id, msg) do
    GenServer.call(via_priv_channels(id), msg)
  end


  def start_link(%{"id" => id} = priv_channel) do
    GenServer.start_link(__MODULE__, priv_channel, name: via_priv_channels(id))
  end


  def add_priv_channel(channel) do
    Supervisor.start_child(PrivChanSupervisor, [channel])
  end


  def update_priv_channel(%{"id" => id} = channel) do
    call(id, {:swap, channel})
  end


  def rem_priv_channel(id) do
    Supervisor.terminate_child(GuildSupervisor, via_priv_channels(id))
  end

  ### Server ###

  def handle_call({:swap, new}, _, _) do
    {:reply, :ok, new}
  end
end
