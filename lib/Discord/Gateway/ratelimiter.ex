defmodule Alchemy.Discord.Gateway.RateLimiter do
  @moduledoc false
  # This servers as a limiter to outside requests to the individual gateways
  use Bitwise
  alias Alchemy.Discord.Payloads

  defmodule RateSupervisor do
    @moduledoc false
    alias Alchemy.Discord.Gateway.RateLimiter
    use Supervisor

    def start_link do
      Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
    end

    def init(:ok) do
      children = [
        worker(RateLimiter, [])
      ]

      supervise(children, strategy: :simple_one_for_one)
    end
  end

  def add_handler(pid) do
    Supervisor.start_child(__MODULE__.RateSupervisor, [pid])
  end

  def status_update(pid, idle_since, game_info) do
    Task.async(fn ->
      payload = Payloads.status_update(idle_since, game_info)
      send_request(pid, {:status_update, payload})
    end)
  end

  def shard_pid(guild, name \\ __MODULE__.RateSupervisor) do
    {guild_id, _} = Integer.parse(guild)

    shards =
      Supervisor.which_children(name)
      |> Enum.map(fn {_, pid, _, _} -> pid end)

    Enum.at(shards, rem(guild_id >>> 22, length(shards)))
  end

  def request_guild_members(guild_id, username, limit) do
    payload = Payloads.request_guild_members(guild_id, username, limit)

    shard_pid(guild_id)
    |> send_request({:send_event, payload})
  end

  def change_voice_state(guild_id, channel_id, mute \\ false, deaf \\ false) do
    payload = Payloads.voice_update(guild_id, channel_id, mute, deaf)

    shard_pid(guild_id)
    |> send_request({:send_event, payload})
  end

  # Handles the rate
  defp send_request(pid, request) do
    case GenServer.call(pid, request) do
      :ok ->
        :ok

      {:wait, time} ->
        Process.sleep(time)
        send_request(pid, request)
    end
  end

  defp handle_wait(now, reset_time) do
    wait_time = reset_time - now

    if wait_time < 0 do
      :go
    else
      {:wait, wait_time}
    end
  end

  defp wait_protocol(data, timeout, section, state) do
    now = System.monotonic_time(:milliseconds)

    case handle_wait(now, get_in(state, [section, :reset])) do
      :go ->
        send(state.gateway, {:send_event, data})

        new =
          update_in(state, [section], fn x ->
            %{x | left: 0, reset: now + timeout}
          end)

        {:reply, :ok, new}

      {:wait, time} ->
        {:reply, {:wait, time}, state}
    end
  end

  def start_link(gateway) do
    GenServer.start_link(__MODULE__, {:ok, gateway})
  end

  def init({:ok, gateway}) do
    now = System.monotonic_time(:millisecond)

    state = %{
      gateway: gateway,
      status_update: %{left: 1, reset: now + 12_000},
      events: %{left: 100, reset: now + 60_000}
    }

    {:ok, state}
  end

  def handle_call({:send_event, data}, _from, %{events: %{left: 0}} = state) do
    wait_protocol(data, 60_000, :events, state)
  end

  def handle_call({:send_event, data}, _from, state) do
    send(state.gateway, {:send_event, data})
    {:reply, :ok, update_in(state.events.left, &(&1 - 1))}
  end

  def handle_call({:status_update, data}, _from, %{status_update: %{left: 1}} = state) do
    send(state.gateway, {:send_event, data})
    {:reply, :ok, update_in(state.status_update.left, &(&1 - 1))}
  end

  def handle_call({:status_update, data}, _from, state) do
    wait_protocol(data, 12_000, :status_update, state)
  end
end
