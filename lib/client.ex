defmodule Alchemy.Client do
  @moduledoc """
  Represents a Client connection to the Discord API. This is the main public
  interface for the REST API.
  """
  use Supervisor
  require Logger
  alias Alchemy.Discord.{Users, Channels, Guilds, RateManager}
  alias Alchemy.Discord.Gateway.Manager, as: GatewayManager
  alias Alchemy.{Channel, Channel.Invite, DMChannel, Reaction.Emoji,
                 Embed, Guild, GuildMember, Message, User, UserGuild, Role}
  alias Alchemy.Cache.Supervisor, as: CacheSupervisor
  alias Alchemy.Cogs.{CommandHandler, EventHandler}
  import Alchemy.Discord.RateManager, only: [send_req: 2]
  use Alchemy.Discord.Types



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
      worker(RateManager, [token]),
      worker(EventHandler, []),
      worker(CommandHandler, [options]),
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
    {Users, :get_user, [client_id]}
    |> send_req("/users/#{client_id}")
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
     {Users, :modify_user, [options]}
     |> send_req("/users/@me")
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
     {Users, :get_current_guilds, []}
     |> send_req("/users/@me/guilds")
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
    {Users, :leave_guild, [guild_id]}
    |> send_req("/users/@me/guilds/#{guild_id}")
   end
   @doc """
   Gets a list of private channels open with this user.

   ## Examples
   ```elixir
   Client.get_DMs()
   ```
   """
   @spec get_DMs :: [DMChannel.t]
   def get_DMs do
     {Users, :get_DMs, []}
     |> send_req("/users/@me/channels")
   end
   @doc """
   Opens a new private channel with a user.

   ## Examples
   Cogs.def dm_me do
    Client.create_DM(message.author.id)
   end
   """
   @spec create_DM(snowflake) :: DMChannel.t
   def create_DM(user_id) do
     {Users, :create_DM, [user_id]}
     |> send_req("/users/@me/channels")
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
     {Channels, :get_channel, [channel_id]}
     |> send_req("/channels/#{channel_id}")
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
     {Channels, :modify_channel, [channel_id, options]}
     |> send_req("/channels/#{channel_id}")
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
     {Channels, :delete_channel, [channel_id]}
     |> send_req("/channels/#{channel_id}")
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
     {Channels, :channel_messages, [channel_id, options]}
     |> send_req("/channels/#{channel_id}/messages")
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
     {Channels, :channel_message, [channel_id, message_id]}
     |> send_req("/channels/#{channel_id}/messages/#{message_id}")
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
     {Channels, :create_message, [channel_id, options]}
     |> send_req("/channels/#{channel_id}/messages")
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
     {Channels, :edit_message, [channel_id, message_id, opts]}
     |> send_req("/channels/#{channel_id}/messages")
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
     {Channels, :edit_message, [channel_id, id, [embed: Embed.build(embed)]]}
     |> send_req("/channels/#{channel_id}/messages")
   end
   def edit_embed({channel_id, id} = message, embed) do
     {Channels, :edit_message, [channel_id, id, [embed: Embed.build(embed)]]}
     |> send_req("/channels/#{channel_id}/messages")
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
     {Channels, :delete_message, [channel_id, id]}
     |> send_req("del/channels/#{channel_id}/messages")
   end
   def delete_message({channel_id, message_id} = message) do
     {Channels, :delete_message, [channel_id, message_id]}
     |> send_req("del/channels/#{channel_id}/messages")
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
     {Channels, :delete_messages, [channel_id, messages]}
     |> send_req("del/channels/#{channel_id}/messages/bulk-delete")
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
     {Channels, :create_reaction, [channel_id, id, emoji]}
     |> send_req("/channels/#{channel_id}/messages/reactions/@me")
   end
   def add_reaction({channel_id, message_id} = message, emoji) do
     emoji = Emoji.resolve(emoji)
     {Channels, :create_reaction, [channel_id, message_id, emoji]}
     |> send_req("/channels/#{channel_id}/messages/reactions/@me")
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
     {Channels, :delete_own_reaction, [channel_id, id, emoji]}
     |> send_req("/channels/#{channel_id}/messages/reactions/@me")
   end
    def remove_reaction({channel_id, message_id} = message, emoji) do
      emoji = Emoji.resolve(emoji)
      {Channels, :delete_own_reaction, [channel_id, message_id, emoji]}
      |> send_req("/channels/#{channel_id}/messages/reactions/@me")
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
      {Channels, :delete_reaction, [channel_id, id, emoji, user]}
      |> send_req("/channels/#{channel_id}/messages/reactions")
    end
    def delete_reaction({channel_id, message_id}, emoji, user) do
      emoji = Emoji.resolve(emoji)
      user = case user do
        %User{id: id} -> id
        id -> id
      end
      {Channels, :delete_reaction, [channel_id, message_id, emoji, user]}
      |> send_req("/channels/#{channel_id}/messages/reactions")
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
      {Channels, :get_reactions, [channel_id, id, emoji]}
      |> send_req("/channels/#{channel_id}/messages/reactions")
    end
    def get_reactions({channel_id, message_id}, emoji) do
      emoji = Emoji.resolve(emoji)
      {Channels, :get_reactions, [channel_id, message_id, emoji]}
      |> send_req("/channels/#{channel_id}/messages/reactions")
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
      {Channels, :delete_reactions, [channel_id, id]}
      |> send_req("/channels/#{channel_id}/messages/reactions")
    end
    def remove_reactions({channel_id, message_id} = message) do
      {Channels, :delete_reactions, [channel_id, message_id]}
      |> send_req("/channels/#{channel_id}/messages/reactions")
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
      {Channels, :get_channel_invites, [channel_id]}
      |> send_req("/channels/#{channel_id}/invites")
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
      {Channels, :create_channel_invite, [channel_id, options]}
      |> send_req("/channels/#{channel_id}/invites")
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
      {Channels, :trigger_typing, [channel_id]}
      |> send_req("/channels/#{channel_id}/typing")
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
      {Channels, :get_pinned_messages, [channel_id]}
      |> send_req("/channels/#{channel_id}/pins")
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
      {Channels, :add_pinned_message, [channel_id, id]}
      |> send_req("/channels/#{channel_id}/pins")
    end
    def pin({channel_id, message_id}) do
      {Channels, :add_pinned_message, [channel_id, message_id]}
      |> send_req("/channels/#{channel_id}/pins")
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
      {Channels, :delete_pinned_message, [channel_id, id]}
      |> send_req("/channels/#{channel_id}/pins")
    end
    def unpin({channel_id, message_id}) do
      {Channels, :delete_pinned_message, [channel_id, message_id]}
      |> send_req("/channels/#{channel_id}/pins")
    end
    # CACHESTUB
    @doc """
    Gets info about a certain guild.

    The info returned here doesn't contain as much info as contained in the cache.
    For guilds the user is a part of, the cache should be preferred over this method.

    ```examples
    Client.get_guild(id)
    ```
    """
    @spec get_guild(snowflake) :: {:ok, Guild.t} | {:error, term}
    def get_guild(guild_id) do
      {Guilds, :get_guild, [guild_id]}
      |> send_req("/guilds/#{guild_id}")
    end
    @doc """
    Modifies a guild's settings.

    ## Options
    - `name`
      The name of the guild.
    - `region`
      The id of the voice region.
    - `verification_level`
      The level of verification of the guild.
    - `default_message_notifications`
      The default message notification settings.
    - `afk_channel_id`
      The id of the afk channel.
    - `afk_timeout`
      The afk timeout in seconds.
    - `icon`
      A url to the new icon. Must be a 128x128 jpeg image.
    - `splash`
      A url to the new splash screen. This is only available for partnered guilds.

    ## Examples
    ```elixir
    Client.edit_guild(guild_id, name: "new name")
    ```
    """
    @spec edit_guild(snowflake,
                     name: String.t,
                     region: snowflake,
                     verification_level: Integer,
                     default_message_notifications: Integer,
                     afk_channel_id: snowflake,
                     afk_timeout: snowflake,
                     icon: url,
                     splash: url) :: {:ok, Guild.t} | {:error, term}
    def edit_guild(guild_id, options) do
       {Guilds, :modify_guild, [guild_id, options]}
       |> send_req("/guilds/#{guild_id}")
    end
    # CACHESTUB
    @doc """
    Returns a list of channel objects for a guild.

    As with most guild methods, the cache should be preferred
    over the api if possible.

    ## Examples
    ```elixir
    Client.get_channels(guild_id)
    ```
    """
    @spec get_channels(snowflake) :: {:ok, [Channel.t]} | {:error, term}
    def get_channels(guild_id) do
      {Guilds, :get_channels, [guild_id]}
      |> send_req("/guilds/#{guild_id}/channels")
    end
    @doc """
    Creates a new channel in a guild.

    Requires the `MANAGE_CHANNELS` permission.

    ## Options
    - `voice`
      Setting this creates a new voice channel.
    - `bitrate`
      Sets the bitrate (bits) for a voice channel.
    - `user_limit`
      Sets the max amount of users for a voice channel.
    - `permission_overwrites`
      An overwrite for permissions in that channel
    ## Examples
    ```elixir
    Client.create_channel(guild_id)
    ```
    """
    @spec create_channel(snowflake, String.t,
                         voice: Boolean,
                         bitrate: Integer,
                         user_limit: Integer) :: {:ok, Channel.t} | {:error, term}
    def create_channel(guild_id, name, options \\ []) do
      {Guilds, :create_channel, [guild_id, name, options]}
      |> send_req("/guilds/#{guild_id}/channels")
    end
    @doc """
    Swaps the position of channels in a guild.

    ## Examples
    ```elixir
    # alphabetizes a guild channel list
    with {:ok, channels} <- Task.await Client.get_channels(guild_id) do
      channels
      |> Enum.sort_by(& &1.name)
      |> Stream.map(& &1.id)
      |> Enum.with_index
      |> (&Client.move_channels(guild_id, &1)).()
    end
    """
    @spec move_channels(snowflake, [{snowflake, Integer}]) :: {:ok, nil}
                                                            | {:error, term}
    def move_channels(guild_id, pairs) do
      {Guilds, :move_channels, [guild_id, pairs]}
      |> send_req("/guilds/#{guild_id}/channels")
    end
    # CACHESTUB
    @doc """
    Gets info for a member of a guild.

    For guilds the bot is in, use the corresponding cache method instead.

    ## Examples
    ```elixir
    Client.get_member(guild_id, user_id)
    ```
    """
    @spec get_member(snowflake, snowflake) :: {:ok, GuildMember.t} | {:error, term}
    def get_member(guild_id, user_id) do
      {Guilds, :get_member, [guild_id, user_id]}
      |> send_req("/guilds/#{guild_id}/members")
    end
    # CACHESTUB
    @doc """
    Gets a list of members from a guild.

    ## Options
    - `limit`
      The number of members to fetch (max 1000).
    - `after`
      Setting this to a user id will only fetch members that joined after that person.
    ## Examples
    ```elixir
    Client.get_member_list(guild_id, limit: 10)
    ```
    """
    @spec get_member_list(snowflake,
                          limit: Integer, after: snowflake) :: {:ok, [GuildMember.t]}
                                                             | {:error, term}
    def get_member_list(guild_id, options \\ []) do
      {Guilds, :get_member_list, [guild_id, options]}
      |> send_req("/guilds/#{guild_id}/members")
    end
    # SUGARSTUB
    @doc """
    Modifies a member in a guild.

    Each option requires different permissions.
    ## Options
    - `nick`
      The nickname of the user. Requires `:manage_nicknames`
    - `roles`
      A list of roles (ids) the user should have after the change.
      Requires `:manage_roles`
    - `mute`
      Whether or not the user should be muted. Requires `:mute_members`
    - `deaf`
      Whether or not the user should be deafened. Requires `:deafen_members`
    - `channel_id`
      Voice channel to move the user too (if they are connected).
      Requires `:move_members`, and permission to connect to that channel.
    ## Examples
    ```elixir
    Client.edit_member(guild_id, user_id, nick: "cool guy")
    ```
    """
    @spec edit_member(snowflake, snowflake,
                      nick: String.t,
                      roles: [snowflake],
                      mute: Boolean,
                      deaf: Boolean,
                      channel_id: snowflake) :: {:ok, GuildMember.t} | {:error, term}
    def edit_member(guild_id, user_id, options) do
      {Guilds, :modify_member, [guild_id, user_id, options]}
      |> send_req("/guilds/#{guild_id}/members")
    end
    @doc """
    Modifies the nickname of the current user.

    ## Examples
    ```elixir
    Client.change_nickname(guild_id, "best bot")
    ```
    """
    @spec change_nickname(snowflake, String.t) :: {:ok, nil} | {:error, term}
    def change_nickname(guild_id, name) do
      {Guilds, :modify_nick, [guild_id, name]}
      |> send_req("/guilds/#{guild_id}/members/@me/nick")
    end
    # SUGARSTUB
    @doc """
    Adds a role to a member of a guild.

    Requires the `:manage_roles` permission.
    ## Examples
    ```elixir
    Client.add_role(guild_id, user_id, role_id)
    ```
    """
    @spec add_role(snowflake, snowflake, snowflake) :: {:ok, nil} | {:error, term}
    def add_role(guild_id, user_id, role_id) do
      {Guilds, :add_role, [guild_id, user_id, role_id]}
      |> send_req("/guilds/#{guild_id}/members/roles")
    end
    # SUGARSTUB
    @doc """
    Removes a role of a guild member.

    Requires the `:manage_roles` permission.
    ## Examples
    ```elixir
    Client.remove_role(guild_id, user_id, role_id)
    ```
    """
    @spec remove_role(snowflake, snowflake, snowflake) :: {:ok, nil} | {:error, term}
    def remove_role(guild_id, user_id, role_id) do
      {Guilds, :remove_role, [guild_id, user_id, role_id]}
      |> send_req("/guilds/#{guild_id}/members/roles")
    end
    # SUGARSTUB
    @doc """
    Kicks a member from a guild.

    Not to be confused with `ban_member/3`.
    ## Examples
    ```elixir
    Client.kick_member(guild_id, user_id)
    ```
    """
    @spec kick_member(snowflake, snowflake) :: {:ok, nil} | {:error, term}
    def kick_member(guild_id, user_id) do
      {Guilds, :remove_member, [guild_id, user_id]}
      |> send_req("/guilds/#{guild_id}/members")
    end
    # SUGARSTUB
    @doc """
    Gets a list of users banned from this guild.

    Requires the `:ban_members` permission.
    ## Examples
    ```elixir
    {:ok, bans} = Client.get_bans(guild_id)
    ```
    """
    @spec get_bans(snowflake) :: {:ok, [User.t]} | {:error, term}
    def get_bans(guild_id) do
      {Guilds, :get_bans, [guild_id]}
      |> send_req("/guilds/#{guild_id}/bans")
    end
    # SUGARSTUB
    @doc """
    Bans a member from a guild.

    This prevents a user from rejoining for as long as the ban persists,
    as opposed to `kick_member/2` which will just make them leave the server.

    A `days` paramater can be set to delete x days of messages; limited to 7.
    ## Examples
    ```elixir
    Client.ban_member(guild_id, user_id, 1)
    ```
    """
    @spec ban_member(snowflake, snowflake) :: {:ok, nil} | {:error, term}
    def ban_member(guild_id, user_id, days \\ 0) do
       {Guilds, :create_ban, [guild_id, user_id, days]}
       |> send_req("/guilds/#{guild_id}/bans")
    end
    # SUGARSTUB
    @doc """
    Unbans a user from the server.

    ## Examples
    ```elixir
    Client.unban_member(guild_id, user_id)
    ```
    """
    @spec unban_member(snowflake, snowflake) :: {:ok, nil} | {:error, term}
    def unban_member(guild_id, user_id) do
      {Guilds, :remove_ban, [guild_id, user_id]}
      |> send_req("/guilds/#{guild_id}/bans")
    end
    @doc """
    Gets a list of roles available in a guild.

    Requires the `:manage_roles` permission.
    ## Examples
    ```elixir
    Client.get_roles(guild_id)
    ```
    """
    @spec get_roles(snowflake) :: {:ok, [Role.t]} | {:error, term}
    def get_roles(guild_id) do
      {Guilds, :get_roles, [guild_id]}
      |> send_req("/guilds/#{guild_id}/roles")
    end
    @doc """
    Creates a new role in the guild.

    Requires the `:manage_roles` permission.
    ## Options
    - `name`
      The name of the new role. Defaults to "new role"
    - `permissions`
      The set of permissions for that role. Defaults to the `@everyone`
      permissions in that guild.
    - `color`
      The color of the role. Defaults to `0x000000`
    - `hoist`
      When set to `true`, the role will be displayed seperately in the sidebar.
    - `mentionable`
      When set to `true`, allows the role to be mentioned.
    ## Examples
    ```elixir
    Client.create_role(guild_id, name: "the best role", color: 0x4bd1be)
    ```
    """
    @spec create_role(snowflake,
                      name: String.t,
                      permissions: Integer,
                      color: Integer,
                      hoist: Booean,
                      mentionable: Boolean) :: {:ok, Role.t} | {:error, term}
    def create_role(guild_id, options) do
      {Guilds, :create_role, [guild_id, options]}
      |> send_req("/guilds/#{guild_id}/roles")
    end
    @doc """
    Edits a preexisting role in a guild.

    The same as `create_role/2` except that this operates on a role that has already
    been created. See that function for discussion.
    """
    @spec edit_role(snowflake, snowflake,
                    name: String.t,
                    permissions: Integer,
                    color: Integer,
                    hoist: Booean,
                    mentionable: Boolean) :: {:ok, Role.t} | {:error, term}
    def edit_role(guild_id, role_id, options) do
      {Guilds, :modify_role, [guild_id, role_id, options]}
      |> send_req("/guilds/#{guild_id}/roles")
    end
    @doc """
    Modifies the position of roles in a guild.

    Takes a list of `{id, position}` where `position` is an integer starting at 0,
    and `id` is the id of the role.

    Returns a list of all the roles in the guild.
    """
    @spec move_roles(snowflake, [{snowflake, Integer}]) :: {:ok, [Role.t]}
                                                         | {:error, term}
    def move_roles(guild_id, pairs) do
      {Guilds, :move_roles, [guild_id, pairs]}
      |> send_req("/guilds/#{guild_id}/roles")
    end
end
