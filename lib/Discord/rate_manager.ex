defmodule Alchemy.Discord.RateManager do
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

  # Wrapper around applying for an api slot
  def apply(method) do
    GenServer.call(API, {:apply, method})
  end
  # Wrapper around processing a request
  def process(module, method, args) do
    GenServer.call(API, {module, method, args})
  end
  # A requester needs to request a slot from here. It will either be told to wait,
  # or to go, in which case it calls the server again for an api call
  def handle_call({:apply, method}, _from, state) do
    rates = state.rates
    rate_info = Map.get(rates, method, default_info)
    IO.inspect rate_info
    case throttle(rate_info) do
      {:wait, time} ->
        Logger.info "Timeout of #{time} under request #{method}"
        {:reply, {:wait, time}, state}
      {:go, new_rates} ->
        reserved = Map.merge(rate_info, new_rates)
        new_state = %{state | rates:  Map.put(rates, method, reserved)}
        {:reply, :go, new_state}
    end
  end
  def handle_call({module, method, args}, _from, state) do
    # Call the specific method requested
    result = apply(module, method, [state.token | args])
    # Use the method name as the key, update the rates if they're not :none
    {reply, newstate} =
    with {:ok, info, rate_info} <- result do
       new_rates = update_rates(state, method, rate_info)
       {info, %{state | rates: new_rates}}
    end
    {:reply, reply, newstate}
  end

  # Sets the new rate_info for a given bucket to the rates recieved from an api call
  # If the info is :none, the rates are not be modified
  def update_rates(state, _bucket, :none) do
    state.rates
  end
  def update_rates(state, bucket, rate_info) do
    Map.put(state.rates, bucket, rate_info)
  end

  # Assigns a slot to an incoming request,
  def throttle(%RateInfo{remaining: remaining}) when remaining > 0 do
      {:go, %{remaining: remaining - 1}}
  end
  def throttle(rate_info) do
    now = DateTime.utc_now |> DateTime.to_unix
    reset_time = rate_info.reset_time
    wait_time = reset_time - now
    if wait_time > 0 do
      {:wait, wait_time * 1000}
    else
      # We've passed the limit, remaining can be reset to the limit.
      # To ensure that we don't overreserve for this time slot, we set the next
      # reset time to 2 seconds from now; This should be replaced with info
      # coming from outgoing requests within that timeframe
      {:go, %{remaining: rate_info.limit - 1, reset_time: now + 2}}
    end
  end


  # A helper function for some of the later functions.
  # This wraps a syncronous RateManager call into a new process, allowing
  # for concurrent http requests
  def send(req), do: Task.async(fn -> request(req) end)

  # Used to wait a certain amount of time if the rate_manager can't handle the load
  defp request({m, f, a} = req) do
    case apply(f) do
      {:wait, n} ->
        Process.sleep(n)
        apply(req)
      :go ->
        process(m, f, a)
    end
  end
end
