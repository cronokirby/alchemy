defmodule Alchemy.RateManager do
  use GenServer
  @moduledoc false
  # Used to keep track of rate limiting. All api requests are funneled from
  # the public Client interface into this server.

  defmodule State do
    @moduledoc false
    defstruct [:token, count: 1]
  end

  # Starts up the RateManager. The Client token needs to be passed in.
  def start_link(state, opts \\ []) do
    GenServer.start_link(__MODULE__, struct(State, state), opts)
  end

  # Takes a specific API request, and handles storing the ratelimits.
  # This will be called from inside a Task, to allow for concurrent API requests.
  def handle_call({module, method, args}, _from, state) do
    {:ok, info} = apply(module, method, [state.token | args])
    {:reply, {:ok, info}, state}
  end
  
end
