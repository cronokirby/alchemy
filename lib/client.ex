defmodule Alchemy.Client do
  require Logger
  alias Alchemy.Discord.{Users, Channels, RateManager}
  alias Alchemy.Discord.Gateway.Manager, as: GatewayManager
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
      worker(CacheManager, [[name: ClientState]]),
      worker(GatewayManager, [token])
    ]
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

   - `user_name` A string specifiying the new user_name for the client
   - `avatar` A link to an image for the client's avatar

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
     send {Users, :modify_user, [options]}
   end
   @doc """
   Gets a list of guilds the client is currently a part of.

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
     send {Channels, :get_channel, [channel_id]}
   end
   @doc """
   Edits a channel in a guild, referenced by id.

   All the paramaters are optional. Some are mutually exclusive. I.E.
   you can't use voice only and text only parameters in the same request.

   ## Options
   - `name` the name for the channel
   - `position` the position in the left hand listing
   - `topic` ~ *text only* ~ the topic of the channel
   - `bitrate` ~ *voice only* ~ the bitrate, in bits, from `8000` to `96000`, for
   the voice channel to take
   - `user_limit` ~ *voice only* ~ the max amount of users allowed in this channel.
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
                      user_limit: Integer) :: {:ok, Channel.t}
                                            | {:error, term}
   def edit_channel(channel_id, options) do
     send {Channels, :modify_channel, [channel_id, options]}
   end
   @doc """
   Deletes a channel from a guild.


   Here's an example of how to deal with the possible return types using
   pattern matching:
   ```elixir
   def my_delete(id) do
    {:ok, channel} = Task.await Client.delete_channel(id)
     case channel do
       %DMChannel{} -> "this is a private channel!"
       %Channel{} -> "this is a normal channel!"
     end
   end
   ```
   """
   @spec delete_channel(snowflake) :: {:ok, Channel.t}
                                    | {:ok, DMChannel.t}
                                    | {:error, term}
   def delete_channel(channel_id) do
     send {Channels, :delete_channel, [channel_id]}
   end
   @doc """
   Gets up to `100` messages from a channel.

   `around`, `before`, `after` are all mutually exclusive.

   ## Options
   - `around` will search for messages around the time of a particular message
   - `before` will get messages before a certain message
   - `after` will get messages after a certain message
   - `limit` the number of messages to get. Defaults to `100`

   ## Examples
   ```elixir
   {:ok, messages} = Task.await Client.get_messages(around: id, limit: 40)
   ```
   """
   @spec get_messages(snowflake,
                      around: snowflake,
                      before: snowflake,
                      after: snowflake,
                      limit: Integer) :: {:ok, [Message.t]}
                                       | {:error, term}
   def get_messages(channel_id, options) do
     options = Keyword.put_new(options, :limit, 100)
     send {Channels, :channel_messages, [channel_id, options]}
   end
   @doc """
   Gets a message by channel, and message_id

   Use `get_messages` for a bulk request instead.
   ## Examples
   ```elixir
   {:ok, message} = Task.await Client.get_message(channel, id)
   """
   @spec get_message(snowflake, snowflake) :: {:ok, Message.t} | {:error, term}
   def get_message(channel_id, message_id) do
     send {Channels, :channel_message, [channel_id, message_id]}
   end
   @doc """
   Sends a message to a particular channel

   ## Options
   - `tts` used to set whether or not a message should be text to speech
   - `embed` used to send an `Embed` object along with the message
   ## Examples
   ```elixir
   {:ok, message} = Task.await Client.send_message(chan_id, "pong!")
   ```
   """
   @spec send_message(String.t,
                      tts: Boolean,
                      embed: Embed.t) :: {:ok, Message.t}
                                       | {:error, term}
   def send_message(channel_id, content, options \\ []) do
     options = Keyword.put(options, :content, content)
     send {Channels, :create_message, [channel_id, options]}
   end
end
