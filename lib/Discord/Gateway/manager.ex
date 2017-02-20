defmodule Alchemy.Discord.Gateway.Manager do
  use GenServer
  alias Alchemy.Discord.Gateway
  import Supervisor.Spec
  @moduledoc false
  # Serves as a gatekeeper of sorts, deciding when to let the supervisor spawn new
  # gateway connections. It also keeps track of the url, and where the sharding is.
  # This module is in control of the supervisors child spawning.



defp get_url do
  {:ok, json} = HTTPotion.get("https://discordapp.com/api/v6/gateway/bot").body
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




  def start_link(token) do
    {url, shards} = get_url()
    {:ok, sup} = start_supervisor()
    state = %{url: url,
              url_reset: now(),
              shards: shards,
              started: [],
              token: token,
              supervisor: sup}
    run = GenServer.start_link(__MODULE__, state, GatewayManager)
    GenServer.cast(GatewayManager, :start_sharding)
    run
  end


  def handle_call(:url_req, _from, state) do
    wait_time = state.url_reset - now
    cond do
      wait_time <= 0 ->
        fn -> state.url end
      true ->
        fn ->
          Process.sleep(wait_time)
          __MODULE__.request_url()
        end
    end
  end


  def handle_cast({:start_shard, num}, %{shards: shards} = state)
  when num == shards do
    {:noreply, state}
  end
  def handle_cast({:start_shard, num}, state) do

  end
end
