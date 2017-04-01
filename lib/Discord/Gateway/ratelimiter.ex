defmodule Alchemy.Discord.Gateway.RateLimiter do
  @moduledoc false
  # This servers as a limiter to outside requests to the individual gateways
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


  def status_update(pid, idle_since, game_name) do
    Task.async(fn ->
      send_status_update(pid, Payloads.status_update(idle_since, game_name))
    end)
  end

  # Handles the rate
  defp send_status_update(pid, data) do
    case GenServer.call(pid, {:status_update, data}) do
      :ok ->
        :ok
      {:wait, time} ->
        Process.sleep(time)
        send_status_update(pid, data)
    end
  end

  defp handle_wait(now, reset_time) do
    wait_time = reset_time - now
    cond do
      wait_time < 0 ->
        :go
      wait_time == 0 ->
        {:wait, 1000}
      true ->
        {:wait, wait_time * 1000}
    end
  end

  def start_link(gateway) do
    GenServer.start_link(__MODULE__, {:ok, gateway})
  end

  def init({:ok, gateway}) do

    now = DateTime.utc_now() |> DateTime.to_unix
    state = %{gateway: gateway,
              status_update: %{left: 1, reset: now + 12}}
    {:ok, state}
  end


  def handle_call({:status_update, data}, _from,
                  %{status_update: %{left: 1}} = state) do
    send(state.gateway, {:status_update, data})
    {:reply, :ok, update_in(state.status_update.left, & &1 - 1)}
  end
  def handle_call({:status_update, data}, _from, state) do
    now = DateTime.utc_now() |> DateTime.to_unix
    case handle_wait(now, state.status_update.reset) do
      :go ->
        send(state.gateway, {:status_update, data})
        status_update = %{state.status_update | left: 0, reset: now + 12}
        {:reply, :ok, %{state | status_update: status_update}}
      {:wait, time} ->
        {:reply, {:wait, time}, state}
    end
  end
end
