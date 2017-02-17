defmodule Alchemy.Client do
  require Logger
  alias Alchemy.Discord.{Users, Channel, RateManager, Gateway}
  alias Alchemy.{User, UserGuild, Channel, DMChannel}
  alias Alchemy.Cache.Manager, as: CacheManager
  alias Alchemy.Cogs.{CommandHandler, EventHandler}
  import Alchemy.Discord.RateManager, only: [send: 1]
  use Alchemy.Discord.Types
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
      worker(CommandHandler, []),
      worker(CacheManager, [[name: ClientState]])
    ]
    Gateway.start_link(token)
    supervise(children, strategy: :one_for_one)
  end


  ### Public ###

  @doc """
  Gets a user by their client_id.

  `"@me"` can be passed to get the info
  relevant to the Client.

  ## Examples

  ```elixir
  iex> {:ok, user} = Task.await Client.get_user("client_id")
  {:ok, Alchemy.User%{....
  ```
  """
  @spec get_user(snowflake) :: {:ok, User.t} | {:error, term}
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
   {:ok, Alchemy.User%{....
   ```
   """
   @spec edit_profile(username: String.t,
                      avatar: url) :: {:ok, User.t} | {:error, term}
   def edit_profile(options) do
     send {Users, :modify_user, [[options]]}
   end
   @doc """
   Get's a list of guilds the client is currently a part of.

   ## Examples

   ```elixir
   {:ok, guilds} = Task.await Client.current_guilds
   ```
   """
   @spec get_current_guilds() :: {:ok, [UserGuild.t]} | {:error, term}
   def get_current_guilds do
     send {Users, :get_current_guilds, []}
   end
   @doc """
   Makes the client leave a guild.

   ## Examples

   ```elixir
   Client.leave_guild
   ```
   """
   @spec leave_guild(snowflake) :: {:ok, nil} | {:error, term}
   def leave_guild(guild_id) do
    send {Users, :leave_guild, [guild_id]}
   end
   @doc """
   Gets a channel by its ID. Works on both private channels, and guild channels.

   ## Examples
   ```elixir
   {:ok, channel} = Task.await Client.get_channel("id")
   ```
   """
   @spec get_channel(snowflake) :: {:ok, Channel.t}
                                 | {:ok, DMChannel.t}
                                 | {:error, term}
   def get_channel(channel_id) do
     send {Channel, :get_channel, [channel_id]}
   end
   @doc """
   Edits a channel in a guild, referenced by id.

   All the paramaters are optional. Some are mutually exclusive. I.E.
   you can't use voice only and text only parameters in the same request.

   ## Options
   - `name` The name for the channel
   - `position` The position in the left hand listing
   - `topic` ~ *text only* ~ The topic of the channel
   - `bitrate` ~ *voice only* ~ The bitrate, in bits, from `8000` to `96000`, for
   the voice channel to take
   - `user_limit` ~ *voice only* ~ The max amount of users allowed in this channel.
   From `1` to `99`, or `0` for no limit.

   ## Examples
   ```elixir
   Client.edit_channel(id, name: "the best channel", position: 1)
   ```
   ```elixir
   {:ok, new_voice_channel} = Task.await Client.edit_channel(id, bitrate: 8000)
   ```
   """
   @spec edit_channel(snowflake,
                        name: String.t,
                        position: Integer,
                        topic: String.t,
                        bitrate: Integer,
                        user_limit: Integer) :: {:ok, Channel.t} | {:error, term}
   def edit_channel(channel_id, options) do
     send {Channel, :modify_channel, [channel_id, [options]]}
   end


end
