defmodule Alchemy.Discord.Gateway.Manager do
  @moduledoc false
  # Serves as a gatekeeper of sorts, deciding when to let the supervisor spawn new
  # gateway connections. It also keeps track of the url, and where the sharding is.
  # This module is in control of the supervisors child spawning.
  use GenServer
  require Logger
  alias Alchemy.Discord.Gateway
  alias Alchemy.Discord.Api
  import Supervisor.Spec


  ### Public ###

  def request_url do
    Logger.debug "requesting url"
    GenServer.call(GatewayManager, :url_req)
  end


  ### Private Utility ###

  defp get_url(token, selfbot: _) do
    {:ok, json} = Api._get("https://discordapp.com/api/v6/gateway").body
                  |> Poison.Parser.parse
    {json["url"] <> "?v=6&encoding=json", 1}
  end
  defp get_url(token, []) do
    {:ok, json} = Api._get("https://discordapp.com/api/v6/gateway/bot").body
                  |> Poison.Parser.parse
    {json["url"] <> "?v=6&encoding=json",
     json["shards"]}
  end


  defp now, do: DateTime.utc_now |> DateTime.to_unix


  ### Server ###

  def start_supervisor do
    children = [
      worker(Gateway, [])
    ]
    Supervisor.start_link(children, strategy: :simple_one_for_one)
  end


  def start_link(token, options) do
    {url, shards} = get_url(token, options)
    Logger.debug "Starting up #{shards} shards"
    {:ok, sup} = start_supervisor()
    state = %{url: url,
              url_reset: now(),
              shards: shards,
              started: [],
              token: token,
              supervisor: sup}
    run = GenServer.start_link(__MODULE__, state, name: GatewayManager)
    GenServer.cast(GatewayManager, {:start_shard, 0})
    run
  end


  def handle_call(:url_req, _from, state) do
    now = now()
    wait_time = state.url_reset - now
    response = cond do
      wait_time <= 0 ->
        fn -> state.url end
      true ->
        fn ->
          Process.sleep(wait_time)
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
    Task.start(fn -> Supervisor.start_child(state.supervisor, args) end)
    Logger.debug "starting shard #{num}..."
    {:noreply, state}
  end


  def handle_info({:next_shard, [shard|_]}, state) do
    GenServer.cast(GatewayManager, {:start_shard, shard + 1})
    {:noreply, state}
  end

end
