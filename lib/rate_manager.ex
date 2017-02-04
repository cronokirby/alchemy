defmodule Alchemy.RateManager do
  use GenServer
  alias Alchemy.Discord.Users
  @moduledoc """
  Used to keep track of rate limiting. All api requests are funneled
  """
  defmodule State do
    defstruct [:token, count: 1]
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, struct(State, opts), name: __MODULE__)
  end

  def handle_call({:get_user, id}, _from, state) do
    {:ok, info} = Users.get_user(id, state.token)
    {:reply, {:ok, info}, state}
  end
  def handle_call(:add, _from, state) do
    count = state.count
    if count == 0 do
      IO.puts "We're being ratelimited, waiting for 4.5 seconds"
      :timer.sleep(4500)
      {:reply, state, %{state | count: 0}}
    else
      {:reply, state, %{state | count: count - 1}}
    end


  end
end
