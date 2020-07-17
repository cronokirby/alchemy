defmodule Alchemy.Discord.Gateway.Manager do
  @moduledoc false
  # Serves as a gatekeeper of sorts, deciding when to let the supervisor spawn new
  # gateway connections. It also keeps track of the url, and where the sharding is.
  # This module is in control of the supervisors child spawning.
  use GenServer
  require Logger
  alias Alchemy.Discord.Gateway
  alias Alchemy.Discord.Gateway.RateLimiter
  alias Alchemy.Discord.Api
  import Supervisor.Spec

  ### Public ###

  def shard_count do
    GenServer.call(GatewayManager, :shard_count)
  end

  def request_url do
    GenServer.call(GatewayManager, :url_req)
  end

  ### Private Utility ###

  defp get_url(_token, selfbot: _) do
    json =
      Api.get!("https://discord.com/api/v6/gateway").body
      |> (fn x -> Poison.Parser.parse!(x, %{}) end).()

    {json["url"] <> "?v=6&encoding=json", 1}
  end

  defp get_url(token, []) do
    url = "https://discord.com/api/v6/gateway/bot"

    json =
      Api.get!(url, token).body
      |> (fn x -> Poison.Parser.parse!(x, %{}) end).()

    {json["url"] <> "?v=6&encoding=json", json["shards"]}
  end

  defp now, do: DateTime.utc_now() |> DateTime.to_unix()

  ### Server ###

  def start_supervisor do
    children = [
      worker(Gateway, [])
    ]

    Supervisor.start_link(children, strategy: :simple_one_for_one)
  end

  def start_link(token, options) do
    GenServer.start_link(__MODULE__, {token, options}, name: GatewayManager)
  end

  def init({token, options}) do
    {url, shards} = get_url(token, options)
    Logger.info("Starting up #{shards} shards")
    {:ok, sup} = start_supervisor()
    state = %{url: url, url_reset: now(), shards: shards, token: token, supervisor: sup}
    GenServer.cast(GatewayManager, {:start_shard, 0})
    {:ok, state}
  end

  def handle_call(:shard_count, _from, state) do
    {:reply, state.shards, state}
  end

  def handle_call(:url_req, _from, state) do
    now = now()
    wait_time = state.url_reset - now

    response =
      cond do
        wait_time <= 0 ->
          fn -> state.url end

        true ->
          fn ->
            Process.sleep(wait_time * 1000)
            request_url()
          end
      end

    {:reply, response, %{state | url_reset: now + 5}}
  end

  def handle_cast({:start_shard, num}, %{shards: shards} = state)
      when num == shards do
    {:noreply, state}
  end

  def handle_cast({:start_shard, num}, state) do
    args = [state.token, [num, state.shards]]
    # We don't want to block the server waiting for url requests and whatnot.
    Task.start(fn ->
      {:ok, pid} = Supervisor.start_child(state.supervisor, args)
      RateLimiter.add_handler(pid)
    end)

    Logger.debug("Starting shard [#{num}, #{state.shards}]")
    {:noreply, state}
  end

  def handle_info({:next_shard, [shard | _]}, state) do
    GenServer.cast(GatewayManager, {:start_shard, shard + 1})
    {:noreply, state}
  end
end
