defmodule Alchemy.Voice.Supervisor do
  @moduledoc false
  # Supervises the voice section, including a registry and the dynamic
  # voice client supervisor.
  use Supervisor
  alias Alchemy.Discord.Gateway.RateLimiter
  use Alchemy.Voice.Macros

  alias __MODULE__.Server

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  simple_supervisor(Controller, Alchemy.Voice.Controller)
  simple_supervisor(Gateway, Alchemy.Voice.Gateway)

  def init(:ok) do
    children = [
      supervisor(Registry, [:unique, __MODULE__.Registry]),
      supervisor(Alchemy.Voice.Supervisor.Controller, []),
      supervisor(Alchemy.Voice.Supervisor.Gateway, []),
      worker(__MODULE__.Server, [])
    ]

    supervise(children, strategy: :one_for_one)
  end

  defmodule Registry do
    @moduledoc false
    def via(key) do
      {:via, Registry, {__MODULE__, key}}
    end
  end

  defmodule Server do
    @moduledoc false
    use GenServer

    def start_link do
      GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
    end

    def send_to(guild, data) do
      GenServer.cast(__MODULE__, {:send_to, guild, data})
    end

    def handle_call({:start_client, guild}, {pid, _}, state) do
      case Map.get(state, guild) do
        nil ->
          {:reply, :ok, Map.put(state, guild, pid)}
        _ ->
          {:reply, {:error, "Already joining this guild"}, state}
      end
    end

    def handle_cast({:send_to, guild, data}, state) do
      case Map.get(state, guild) do
        nil -> nil
        pid -> send(pid, data)
      end
      {:noreply, state}
    end
  end

  def start_client(guild, channel, timeout \\ 5_000) do
    with :ok <- GenServer.call(Server, {:start_client, guild}) do
      RateLimiter.change_voice_state(guild, channel)
      # We're waiting on 2 events from the gateway here:
      {user_id, session} = receive do
        x -> x
      end
      {token, url} = receive do
        x -> x
      end

    end
  end
end
