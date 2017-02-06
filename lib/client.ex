defmodule Alchemy.Client do
  alias Alchemy.Discord.Users
  alias Alchemy.UserGuild
  alias Alchemy.User

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
  Gets a user by their client_id, returns `{:ok, %User{}}`

  `"@me"` can be passed to get the info
  relevant to the Client.

  ## Examples

  ```elixir
  iex> {:ok, user} = Task.await Client.get_user('client_id')
  {:ok, Alchemy.Discord.Users.User%{....
  ```
  """
  @spec get_user(String.t) :: {:ok, User.t}
  def get_user(client_id) do
    request = {Users, :get_user, [client_id]}
    send(request)
   end
   @doc """
   Edits the client's user_name and/or avatar.

   ## Options

   - `user_name` - A string specifiying the new user_name for the client
   - `avatar` - A link to an image for the client's avatar

   ## Examples

   ```elixir
   # Will edit "behind the scenes"
   Client.edit_profile(username: "NewGuy", avatar: "imgur.com/image.jpeg")
   ```
   ```elixir
   iex> {:ok, user} = Task.await Client.edit_profile(username: "NewName")
   {:ok, Alchemy.Discord.Users.User%{....
   ```
   """
   @spec edit_profile(user_name: String.t, avatar: String.t) :: {:ok, User.t}
   def edit_profile(options) do
     send({Users, :modify_user, options})
   end
   @doc """
   Get's a list of guilds the client is currently a part of.

   ## Examples

   ```elixir
   {:ok, guilds} = Task.await Client.current_guilds
   ```
   """
   @spec current_guilds() :: {:ok, UserGuild.t}
   def current_guilds do
     send {Users, :get_current_guilds, []}
   end
end
