defmodule Alchemy.Voice.Supervisor do
  @moduledoc false
  # Supervises the voice section, including a registry and the dynamic
  # voice client supervisor.
  use Supervisor
  alias Alchemy.Discord.Gateway.RateLimiter
  alias Alchemy.Voice.Supervisor.{Controller, Gateway}
  require Logger

  alias __MODULE__.Server

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  defmodule Gateway do
    use Supervisor

    def start_link do
      Supervisor.start_link(__MODULE__, :ok, name: Gateway)
    end

    def init(:ok) do
      children = [
        worker(Alchemy.Voice.Gateway, [])
      ]

      supervise(children, strategy: :simple_one_for_one)
    end
  end

  def init(:ok) do
    children = [
      supervisor(Registry, [:unique, Registry.Voice]),
      supervisor(Alchemy.Voice.Supervisor.Gateway, []),
      worker(__MODULE__.Server, [])
    ]

    supervise(children, strategy: :one_for_one)
  end

  defmodule VoiceRegistry do
    @moduledoc false
    def via(key) do
      {:via, Registry, {Registry.Voice, key}}
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

    def handle_call({:client_done, guild}, _, state) do
      {:reply, :ok, Map.delete(state, guild)}
    end

    def handle_cast({:send_to, guild, data}, state) do
      case Map.get(state, guild) do
        nil -> nil
        pid -> send(pid, data)
      end
      {:noreply, state}
    end
  end

  def start_client(guild, channel, timeout) do
    r = with :ok <- GenServer.call(Server, {:start_client, guild}),
             [] <- Registry.lookup(Registry.Voice, {guild, :gateway})
      do
        RateLimiter.change_voice_state(guild, channel)
        recv = fn ->
          receive do
            x -> {:ok, x}
          after
            div(timeout, 2) -> {:error, "Timed out"}
          end
        end
        with {:ok, {user_id, session}} <- recv.(),
             {:ok, {token, url}} <- recv.(),
             {:ok, _pid1} <- Supervisor.start_child(Gateway,
               [url, token, session, user_id, guild]),
             {:ok, _pid2} <- recv.()
        do
          :ok
        end
    else
      [{pid, _}|_] ->
        RateLimiter.change_voice_state(guild, channel)
        :ok
    end
    GenServer.call(Server, {:client_done, guild})
    r
  end
end
