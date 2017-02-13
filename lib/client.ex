defmodule Alchemy.Client do
  require Logger
  alias Alchemy.Discord.Users
  alias Alchemy.UserGuild
  alias Alchemy.User
  alias Alchemy.Discord.RateManager
  alias Alchemy.Discord.Gateway
  alias Alchemy.Cache.StateManager
  alias Alchemy.Cogs.EventHandler
  import Alchemy.Discord.RateManager, only: [send: 1]
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
    Supervisor.start_link(__MODULE__, token, name: Client)
  end

  # This creates a `RateManager`, under the name `API` that will be available
  # for managing requests.
  def init(token) do
    children = [
      worker(RateManager, [[token: token], [name: API]]),
      worker(EventHandler, []),
      worker(StateManager, [[name: ClientState]])
    ]
    Gateway.start_link(token)
    supervise(children, strategy: :one_for_one)
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
     send {Users, :modify_user, [options]}
   end
   @doc """
   Get's a list of guilds the client is currently a part of.

   ## Examples

   ```elixir
   {:ok, guilds} = Task.await Client.current_guilds
   ```
   """
   @spec current_guilds() :: {:ok, [UserGuild.t]}
   def current_guilds do
     send {Users, :get_current_guilds, []}
   end
   @doc """
   Makes the client leave a guild.

   ## Examples

   ```elixir
   Client.leave_guild
   ```
   """
   @spec leave_guild(String.t) :: {:ok, :none}
   def leave_guild(guild_id) do
    send {Users, :leave_guild, [guild_id]}
   end
end
