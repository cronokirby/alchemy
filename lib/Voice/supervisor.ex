defmodule Alchemy.Voice.Supervisor do
  @moduledoc false
  # Supervises the voice section, including a registry and the dynamic
  # voice client supervisor.
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = [
      supervisor(Registry, [:unique, __MODULE__.Registry]),
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

    def handle_call({:start_client, guild}, {pid, _}, state) do
      case Map.get(state, guild) do
        nil ->
          {:reply, :ok, Map.put(state, guild, pid)}
        _ ->
          {:reply, {:error, "Already joining this guild"}, state}
      end
    end
  end
end
