defmodule Alchemy.RateManager do
  use GenServer
  alias Alchemy.Discord.Users
  @moduledoc """
  Used to keep track of rate limiting. All api requests are funneled from
  the public Client interface into this server.
  """
  defmodule State do
    defstruct [:token, count: 1]
  end

  @doc """
  Starts up the RateManager. The Client token needs to be passed in.
  """
  def start_link(state, opts \\ []) do
    GenServer.start_link(__MODULE__, struct(State, state), opts)
  end
  @doc """
  Takes a specific API request, and handles storing the ratelimits.
  This will be called from inside a Task, to allow for concurrent API requests.
  """
  def handle_call({module, method, args}, _from, state) do
    {:ok, info} = apply(module, method, args)
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
