defmodule Alchemy.RateManager do
  use GenServer
  require Logger
  import Alchemy.Discord.RateLimits
  alias Alchemy.Discord.RateLimits.RateInfo
  @moduledoc false
  # Used to keep track of rate limiting. All api requests are funneled from
  # the public Client interface into this server.

  defmodule State do
    @moduledoc false
    defstruct [:token, rates: %{}]
  end

  # Starts up the RateManager. The Client token needs to be passed in.
  def start_link(state, opts \\ []) do
    GenServer.start_link(__MODULE__, struct(State, state), opts)
  end

  def handle_call(:rates, _from, state) do
    {:reply, {:ok, state.rates}, state}
  end

  # Takes a specific API request, and handles storing the ratelimits.
  # This will be called from inside a Task, to allow for concurrent API requests.
  def handle_call({:apply, method}, _from, state) do
    rates = state.rates
    rate_info = Map.get(rates, method, default_info)
    IO.inspect rate_info
    case throttle(rate_info) do
      {:wait, time} ->
        Logger.info "Timeout of #{time} under request #{method}"
        {:reply, {:wait, time}, state}
      {:go, remaining} ->
        reserved = %{rate_info | remaining: remaining}
        new_state = %{state | rates:  Map.put(rates, method, reserved)}
        Logger.info "You may go!"
        {:reply, :go, new_state}
    end
  end
  def handle_call({module, method, args}, _from, state) do
    # Call the specific method requested
    {:ok, info, rate_info} = apply(module, method, [state.token | args])
    # Use the method name as the key, update the rates if they're not :none
    new_rates = update_rates(state, method, rate_info)
    {:reply, {:ok, info}, %{state | rates: new_rates}}
  end

  # Sets the new rate_info for a given bucket to the rates recieved from a request
  # If the info is :none, the rates are not be modified
  def update_rates(state, _bucket, :none) do
    state.rates
  end
  def update_rates(state, bucket, rate_info) do
    IO.inspect(rate_info.reset_time - System.system_time(:second))
    Map.put(state.rates, bucket, rate_info)
  end

  def throttle(%RateInfo{remaining: remaining}) when remaining > 0 do
      Logger.info "No throttle"
      {:go, remaining - 1}
  end
  def throttle(rate_info) do
    now = DateTime.utc_now |> DateTime.to_unix
    wait_time = rate_info.reset_time - now
    if wait_time > 0 do
      {:wait, wait_time * 1000}
    else
      # Since we've passed the epoch time, the remaining reqs can be reset.
      # We subtract one to reserve a slot for this request
      {:go, rate_info.limit - 1}
    end
  end

end
