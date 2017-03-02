defmodule Alchemy.Client do
  @moduledoc """
  Represents a Client connection to the Discord API. This is the main public
  interface for the REST API.
  """
  require Logger
  alias Alchemy.Discord.{Users, Channels, RateManager}
  alias Alchemy.Discord.Gateway.Manager, as: GatewayManager
  alias Alchemy.{Channel, Channel.Invite, DMChannel, Reaction.Emoji,
                 Embed, Message, User, UserGuild}
  alias Alchemy.Cache.Manager, as: CacheManager
  alias Alchemy.Cache.Supervisor, as: CacheSupervisor
  alias Alchemy.Cogs.{CommandHandler, EventHandler}
  import Alchemy.Discord.RateManager, only: [send: 1]
  use Alchemy.Discord.Types
  use Supervisor


  @doc """
  Starts up a new Client with the given token.
  """
  @spec start(token, selfbot: snowflake) :: {:ok, pid}
  def start(token) do
    start_link(token, [])
  end
  def start(token, selfbot: id) do
    Application.put_env(:alchemy, :self_bot, " ")
    start_link(token, selfbot: id)
  end

  @doc false
  defp start_link(token, options) do
    Supervisor.start_link(__MODULE__, {token, options}, name: Client)
  end


  # This creates a `RateManager`, under the name `API` that will be available
  # for managing requests.
  def init({token, options}) do
    children = [
      worker(RateManager, [[token: token], [name: API]]),
      worker(EventHandler, []),
      worker(CommandHandler, [options]),
      worker(CacheManager, [[name: ClientState]]),
      worker(GatewayManager, [token, options]),
      supervisor(CacheSupervisor, [])
    ]
    supervise(children, strategy: :one_for_one)
  end


  ### Public ###

  @type unicode :: String.t
  @type channel_id :: snowflake
  @type message_id :: snowflake
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
   Client.leave_guild(guild_id)
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
     {_, options} = options
                  |> Keyword.put(:content, "#{content}")
                  |> Keyword.get_and_update(:embed, fn
                    nil -> :pop
                    some -> {some, Embed.build(some)}
                  end)
     send {Channels, :create_message, [channel_id, options]}
   end
   @doc """
   Edits a message's contents.

   ## Examples
   ```elixir
   {:ok, message} = Task.await Client.send_message(channel, "ping!")
   Process.sleep(1000)
   Client.edit_message(message, "not ping anymore!")
   ```
   """
   @spec edit_message(Message.t | {channel_id, message_id},
                      String.t) :: {:ok, Message.t}
                                 | {:error, term}
   def edit_message(message, content, opts \\ []) do
     {channel_id, message_id} = case message do
       %Message{channel_id: channel_id, id: id} ->
         {channel_id, id}
       tuple ->
         tuple
     end
     opts = Keyword.put(opts, :content, content)
     send {Channels, :edit_message, [channel_id, message_id, opts]}
   end
   @doc """
   Edits a previously sent embed.

   Note that this can be accomplished via `edit_message/3` as well, but that requires
   editing the content as well.

   ```elixir
   Cogs.def embed do
    embed = %Embed{description: "the best embed"}
            |> color(0xc13261)
    {:ok, message} = Task.await Cogs.send(embed)
    Process.sleep(2000)
    Client.edit_embed(message, embed |> color(0x5aa4d4))
   end
   ```
   """
   @spec edit_embed(Message.t | {channel_id, message_id}, Embed.t) :: {:ok, Message.t}
                                                                    | {:error, term}
   def edit_embed(%Message{channel_id: channel_id, id: id}, embed) do
     send {Channels, :edit_message, [channel_id, id, [embed: Embed.build(embed)]]}
   end
   def edit_embed({channel_id, id} = message, embed) do
     send {Channels, :edit_message, [channel_id, id, [embed: Embed.build(embed)]]}
   end
   @doc """
   Deletes a message.

   Requires the `MANAGE_MESSAGES` permission for messages not sent by the user.
   ## Examples
   ```elixir
   content = "self destructing in 1s!!!"
   {:ok, message} = Task.await Client.send_message(channel_id, content)
   Process.sleep(1000)
   Client.delete_message(message)
   ```
   """
   @spec delete_message(Message.t | {channel_id, message_id}) ::
                       {:ok, nil} | {:error, term}
   def delete_message(%Message{channel_id: channel_id, id: id}) do
     send {Channels, :delete_message, [channel_id, id]}
   end
   def delete_message({channel_id, message_id} = message) do
     send {Channels, :delete_message, [channel_id, message_id]}
   end
   @doc """
   Deletes a list of messages.

   Requires the `MANAGE_MESSAGES` permission for messages not posted by this user.
   Can only delete messages up to 2 weeks old.

   ```elixir
    Cogs.def countdown do
      {:ok, m1} = Task.await Cogs.say "3..."
      Process.sleep(1000)
      {:ok, m2} = Task.await Cogs.say "2..."
      Process.sleep(1000)
      {:ok, m3} = Task.await Cogs.say "1..."
      Process.sleep(1000)
      Client.delete_messages(message.channel, [m1, m2, m3])
    end
   """
   @spec delete_messages(snowflake, [Message.t | snowflake]) :: {:ok, nil}
                                                              | {:error, term}
   def delete_messages(channel_id, messages) do
     messages = Enum.map(messages, fn
       %{id: id} -> id
       id -> id
     end)
     send {Channels, :delete_messages, [channel_id, messages]}
   end
   @doc """
   Adds a reaction to a message.

   This supports sending either a custom emoji object, or a unicode literal.
   While sending raw unicode is technically possible, you'll usually run
   into url encoding issues due to hidden characters if you try to send something like
   "❤️️"; use `\\u2764` instead.

   ## Examples
   ```elixir
   Cogs.def heart do
     Client.add_reaction(message, "️\\u2764")
   end
   ```
   """
   @spec add_reaction(Message.t | {channel_id, message_id},
                      unicode | Emoji.t) :: {:ok, nil} | {:error, term}
   def add_reaction(%Message{channel_id: channel_id, id: id}, emoji) do
     emoji = Emoji.resolve(emoji)
     send {Channels, :create_reaction, [channel_id, id, emoji]}
   end
   def add_reaction({channel_id, message_id} = message, emoji) do
     emoji = Emoji.resolve(emoji)
     send {Channels, :create_reaction, [channel_id, message_id, emoji]}
   end
   @doc """
   Removes a reaction on a message, posted by this user.

   This doesn't require the `MANAGE_MESSAGES` permission, unlike
   `delete_reaction`.

   ## Example
   ```elixir
   Cogs.def indecisive do
   Client.add_reaction(message, "\u2764")
   Process.sleep(3000)
   Client.remove_reaction(message, "\u2764")
   end
   ```
   """
   @spec remove_reaction(Message.t | {channel_id, message_id},
                         unicode | Emoji.t) :: {:ok, nil} | {:error, term}
   def remove_reaction(%Message{channel_id: channel_id, id: id}, emoji) do
     emoji = Emoji.resolve(emoji)
     send {Channels, :delete_own_reaction, [channel_id, id, emoji]}
   end
    def remove_reaction({channel_id, message_id} = message, emoji) do
      emoji = Emoji.resolve(emoji)
      send {Channels, :delete_own_reaction, [channel_id, message_id, emoji]}
    end
    @doc """
    Deletes a reaction added by another user.

    Requires the `MANAGE_MESSAGES` permission.
    """
    @spec delete_reaction(Message.t | {channel_id, message_id},
                          unicode | Emoji.t, snowflake | User.t) :: {:ok, nil}
                                                                  | {:error, term}
    def delete_reaction(%Message{channel_id: channel_id, id: id} = message,
                        emoji, user) do
      emoji = Emoji.resolve(emoji)
      user = case user do
        %User{id: id} -> id
        id -> id
      end
      send {Channels, :delete_reaction, [channel_id, id, emoji, user]}
    end
    def delete_reaction({channel_id, message_id}, emoji, user) do
      emoji = Emoji.resolve(emoji)
      user = case user do
        %User{id: id} -> id
        id -> id
      end
      send {Channels, :delete_reaction, [channel_id, message_id, emoji, user]}
    end
    @doc """
    Gets a list of users who reacted to message with a particular emoji.

    ## Examples
    Cogs.def react do
      {:ok, message} = Task.await Cogs.say("react to this!")
      Process.sleep(10000)
      {:ok, users} = Task.await Client.get_reactions(message, "\u2764")
      Cogs.say("#\{length(users)\} users reacted with a \u2764!")
    end
    """
    @spec get_reactions(Message.t | {channel_id, message_id},
                        unicode | Emoji.t) :: {:ok, [User.t]} | {:error, term}
    def get_reactions(%Message{channel_id: channel_id, id: id}, emoji) do
      emoji = Emoji.resolve(emoji)
      send {Channels, :get_reactions, [channel_id, id, emoji]}
    end
    def get_reactions({channel_id, message_id}, emoji) do
      emoji = Emoji.resolve(emoji)
      send {Channels, :get_reactions, [channel_id, message_id, emoji]}
    end
    @doc """
    Removes all reactions from a message.

    Requires the `MANAGE_MESSAGES` permission.

    ## Examples
    ```elixir
    Cogs.def psyche do
      {:ok, message} = Task.await Cogs.say("react to this")
      Process.sleep(10000)
      Client.delete_reactions(message)
    end
    ```
    """
    @spec remove_reactions(Message.t | {channel_id, message_id}) ::
                           {:ok, nil} | {:error, term}
    def remove_reactions(%Message{channel_id: channel_id, id: id}) do
      send {Channels, :delete_reactions, [channel_id, id]}
    end
    def remove_reactions({channel_id, message_id} = message) do
      send {Channels, :delete_reactions, [channel_id, message_id]}
    end
    @doc """
    Gets a list of invites for a channel.

    Only usable for guild channels.
    ## Examples
    ```elixir
    Cogs.def count_invites do
      {:ok, invites} = Client.get_channel_invites(message.channel_id)
                     |> Task.await
      Cogs.say("there are #\{length(invites)\} invites active in this channel")
    end
    """
    @spec get_invites(snowflake) :: {:ok, [Invite.t]} | {:error, term}
    def get_invites(channel_id) do
      send {Channels, :get_channel_invites, [channel_id]}
    end
    @doc """
    Creates a new invite for a channel.

    Requires the `CREATE_INSTANT_INVITE` permission.

    ## Options
    - `max_age`

      The duration (seconds) of the invite. `0` for never.
    - `max_uses`

      The max number of uses. `0` for unlimited.
    - `temporary`

      Whether this invite grants temporary membership.
    - `unique`

      When set, a similar invite won't try to be used.
      Useful for creating unique one time use invites.

    ## Examples
    ```elixir
    Cogs.def invite do
      {:ok, invite} = Task.await Client.create_invite(message.channel_id, max_age: 0)
      Cogs.say("Here you go:\\nhttps://discord.gg/#\{invite.code\}")
    end
    ```
    """
    @spec create_invite(snowflake,
                        max_age: Integer,
                        max_uses: Integer,
                        temporary: Boolean,
                        unique: True) :: {:ok, Invite.t} | {:error, term}
    def create_invite(channel_id, options \\ []) do
      send {Channels, :create_channel_invite, [channel_id, options]}
    end
    @doc """
    Triggers the typing indicator.

    This **shouldn't** be used by bots usually.

    ## Examples
    ```elixir
    Cogs.def hard_math do
      Client.trigger_typing(message.channel_id)
      Process.sleep(3000)
      Cogs.say("done!")
    end
    ```
    """
    @spec trigger_typing(snowflake) :: {:ok, nil} | {:error, term}
    def trigger_typing(channel_id) do
      send {Channels, :trigger_typing, [channel_id]}
    end
    @doc """
    Gets a list of pinned messages in a channel.

    ## Examples
    ```elixir
    Cogs.def pins do
      {:ok, pinned} = Task.await Client.get_pins(message.channel_id)
      Cogs.say("there are #\{length(pinned)\} pins in this channel.")
    end
    ```
    """
    @spec get_pins(snowflake) :: {:ok, [Message.t]} | {:error, term}
    def get_pins(channel_id) do
      send {Channels, :get_pinned_messages, [channel_id]}
    end
    @doc """
    Pins a message to its channel.

    ## Examples
    ```elixir
    Cogs.def pin_this do
      Client.pin(message)
    end
    ```
    """
    @spec pin(Message.t | {channel_id, message_id}) :: {:ok, nil} | {:error, term}
    def pin(%Message{channel_id: channel_id, id: id}) do
      send {Channels, :add_pinned_message, [channel_id, id]}
    end
    def pin({channel_id, message_id}) do
      send {Channels, :add_pinned_message, [channel_id, message_id]}
    end
    @doc """
    Removes a pinned message from a channel.

    ## Examples
    ```elixir
    Cogs.def unpin do
      {:ok, [first|_]} = Task.await Client.get_pins(message.channel_id)
      Client.unpin(first)
    end
    ```
    """
    @spec unpin(Message.t | {channel_id, message_id}) :: {:ok, nil} | {:error, term}
    def unpin(%Message{channel_id: channel_id, id: id}) do
      send {Channels, :delete_pinned_message, [channel_id, id]}
    end
    def unpin({channel_id, message_id}) do
      send {Channels, :delete_pinned_message, [channel_id, message_id]}
    end
end
