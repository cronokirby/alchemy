defmodule Alchemy.Client do
  alias Alchemy.Discord.Users
  use Supervisor
  @moduledoc """
  Represents a Client connection to the Discord API. This is the main public
  interface for the library.
  """

  @doc """
  Starts up a new Client with the given token.
  """
  def start(token), do: start_link(token)
  @doc false
  defp start_link(token) do
    Supervisor.start_link(__MODULE__, token)
  end

  # This creates a `RateManager`, under the name `API` that will be available
  # for managing requests.
  def init(token) do
    children = [
      worker(Alchemy.RateManager, [[token: token], [name: API]])
    ]
    supervise(children, strategy: :one_for_one)
  end



  # A helper function for some of the later functions.
  # This wraps a syncronous RateManager call into a new process, allowing
  # for concurrent http requests
  defp send(req), do: Task.async(fn -> apply(req) end)

  # Used to wait a certain amount of time if the rate_manager can't handle the load
  defp apply(req) do
    {module, method, args} = req
    case GenServer.call(API, {:apply, method}) do
      {:wait, n} ->
        :timer.sleep(n)
        apply(req)
      :go ->
        GenServer.call(API, req)
    end
  end
  @doc """
  Gets a user by their client_id. `"@me"` can be passed to get the info
  relevant to the Client.

  ## Examples

  ```elixir
  iex> {:ok, user} = Task.await Client.get_user('client_id')
  {:ok, Alchemy.Discord.Users.User%{....
  ```
  """
  def get_user(client_id) do
    request = {Users, :get_user, [client_id]}
    send(request)
   end

   def current_servers do
     send {Users, :get_current_guilds, []}
   end
end
