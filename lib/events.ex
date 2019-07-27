defmodule Alchemy.Events do
  @moduledoc """
  This module provides raw Event hooks into the various events supplied by
  the gateway.

  To use the macros in this module, it must be `used`. This also defines
  a `__using__` macro for that module, which will then allow those hooks
  to be loaded in the main application via `use`.
  ### Example Usage

  ```elixir
  defmodule Example do
    use Alchemy.Events

    Events.on_message(:inspect)
    def inspect(message) do
      IO.inspect message.content
    end
  end

  defmodule Application do
    use Application
    alias Alchemy.Client

    def start(_type, _args) do
      run = Client.start(@token)
      use Example
      run
    end

  end
  ```
  """
  require Logger
  alias Alchemy.Cogs.EventHandler
  require Alchemy.EventMacros
  import Alchemy.EventMacros

  @doc """
  Unloads all the hooks in a module from the handler.

  If you just want to disable a single function from triggering,
  see `Events.disable/1`.
  ## Examples
  ```elixir
  Client.start(@token)
  use MyEvents
  ```
  If we want to remove this hooks at any point, we can simply do
  ```elixir
  Events.unload(MyEvents)
  ```
  And, to set hook the module back up, all we need to do is:
  ```elixir
  use MyEvents
  ```
  """
  @spec unload(atom) :: :ok
  def unload(module) do
    EventHandler.unload(module)
    Logger.info("*#{inspect(module)}* removed from the event handler")
  end

  @doc """
  Unhooks a function from the event handler.

  If you want to unhook all the functions in a module, see `Events.unload/1`.
  Because you can have multiple hooks with the same name, this function takes
  both the module and the function name.

  ## Examples
  ```elixir
  defmodule Annoying do
    use Alchemy.Events

    Events.on_message(:inspect)
    def inspect(message), do: IO.inspect message.content
  end
  ```
  This function is annoying us, so we can easily disable it:
  ```elixir
  Events.disable(Annoying, :inspect)
  ```
  If we want to turn it back on, we can of course do
  ```elixir
  use Annoying
  ```
  """
  @spec disable(atom, atom) :: :ok
  def disable(module, function) do
    EventHandler.disable(module, function)
    Logger.info("*#{module}.#{function}* unhooked from the event handler")
  end

  @doc """
  Registers a handle triggering whenever a channel gets created.

  `args` : `Alchemy.Channel.t`

  As opposed to `on_DMChannel_create`, this gets triggered when a channel gets
  created in a guild, and not when a user starts a DM with this client.
  ## Examples
  ```elixir
  Events.on_channel_create(:foo)
  def foo(channel), do: IO.inspect channel.name
  ```
  """
  defmacro on_channel_create(func) do
    handle(:channel_create, func)
  end

  @doc """
  Registers a handle triggering whenever a user starts a DM with the client.

  `args` : `Alchemy.Channel.dm_channel`

  As opposed to `on_channel_create`, this event gets triggered when a user
  starts a direct message with this client.
  ## Examples
  ```elixir
  Events.on_DMChannel_create(:foo)
  def foo(%DMChannel{recipients: [user|_]}) do
    IO.inspect user.name <> " just DMed me!"
  end
  ```
  """
  defmacro on_DMChannel_create(func) do
    handle(:dm_channel_create, func)
  end

  @doc """
  Registers a handle triggering whenever a user closes a DM with the client.

  `args` : `Alchemy.Channel.dm_channel`
  """
  defmacro on_DMChannel_delete(func) do
    handle(:dm_channel_delete, func)
  end

  @doc """
  Registers a handle triggering whenever a guild channel gets removed.

  `args` : `Alchemy.Channel.t`
  """
  defmacro on_channel_delete(func) do
    handle(:channel_delete, func)
  end

  @doc """
  Registers a handle triggering whenever this client joins a guild.

  `args` : `Alchemy.Guild.t`

  A good amount of these events fire when the client initially connects
  to the gateway, and don't actually represent the client joining a new guild.
  """
  defmacro on_guild_join(func) do
    handle(:guild_create, func)
  end

  @doc """
  Registers a handle triggering whenever a guild gets updated.

  `args` : `Alchemy.Guild.t`

  A guild gets updated for various reasons, be it a member or role edition,
  or something else. The guild updated with this new info will be sent to the hook.
  """
  defmacro on_guild_update(func) do
    handle(:guild_update, func)
  end

  @doc """
  Registers a handle triggering whenever a guild comes back online.

  `args` : `Alchemy.Guild.t`

  Sometimes due to outages, or other problems, guild may go offline.
  This can be checked via `guild.unavailable`. This event gets triggered whenever
  a guild comes back online after an outage.
  """
  defmacro on_guild_online(func) do
    handle(:guild_online, func)
  end

  @doc """
  Registers a handle triggering whenever the client leaves a guild.

  `args` : `snowflake`

  The id of the guild the client left gets sent to the hook.
  """
  defmacro on_guild_leave(func) do
    handle(:guild_delete, func)
  end

  @doc """
  Registers a handle triggering whenever a guild channel gets updated.

  `args` : `Alchemy.Channel.t`
  ## Examples
  ```elixir
  Events.on_channel_update(:foo)
  def foo(channel) do
    IO.inspect "\#{channel.name} was updated"
  end
  ```
  """
  defmacro on_channel_update(func) do
    handle(:channel_update, func)
  end

  @doc """
  Registers a handle triggering whenever a user gets banned from a guild.

  `args` : `Alchemy.User.t, snowflake`
  The user, as well as the id of the guild they were banned from get passed
  to the hook.
  ## Example
  ```elixir
  Events.on_user_ban(:cancel_ban)
  def cancel_ban(user, guild) do
    Client.unban_member(guild, user.id)
  end
  ```
  """
  defmacro on_user_ban(func) do
    handle(:guild_ban, func)
  end

  @doc """
  Registers a handle triggering whenever a user gets unbanned from a guild.

  `args` : `Alchemy.User.t, snowflake`
  Recieves the user struct, as well as the id of the guild from which the user
  has been unbanned.
  ## Examples
  ```elixir
  Events.on_user_unban(:reban)
  def reban(user, guild) do
    Client.ban_member(guild_id, user.id)
  end
  ```
  """
  defmacro on_user_unban(func) do
    handle(:guild_unban, func)
  end

  @doc """
  Registers a handle triggering whenever a guild's emojis get updated.

  `args` : `[Guild.emoji], snowflake`

  Receives a list of the current emojis in the guild, after this event, and the
  id of the guild itself.
  """
  defmacro on_emoji_update(func) do
    handle(:emoji_update, func)
  end

  @doc """
  Registers a handle triggering whenever a guild's integrations get updated.

  `args` : `snowflake`

  Like other guild events, the info doesn't actually come through this event,
  but through `on_guild_update`. This hook is merely useful for reacting
  to the event having happened.
  """
  defmacro on_integrations_update(func) do
    handle(:integrations_update, func)
  end

  @doc """
  Registers a handle triggering whenever a member joins a guild.

  `args` : `snowflake`

  The information of the member doesn't actually come through this event,
  but through `on_guild_update`.
  """
  defmacro on_member_join(func) do
    handle(:member_join, func)
  end

  @doc """
  Registers a handle triggering when a member leaves a guild.

  `args` : `Alchemy.User.t, snowflake`

  Receives the user that left the guild, and the id of the guild they've left.
  """
  defmacro on_member_leave(func) do
    handle(:member_leave, func)
  end

  @doc """
  Registers a handle triggering when the status of a member changes in a guild.

  `args` : `Alchemy.Guild.Guild.member, snowflake`

  Receives the member that was updated, and the guild they belong to.
  """
  defmacro on_member_update(func) do
    handle(:member_update, func)
  end

  @doc """
  Registers a handle triggering whenever a role gets created in a guild.

  `args` : `Alchemy.Guild.role, snowflake`

  Receives the new role, as well as the id of the guild that it belongs to.
  """
  defmacro on_role_create(func) do
    handle(:role_create, func)
  end

  @doc """
  Registers a handle triggering whenever a role gets updated in a guild.

  `args` : `Alchemy.Guild.role, Alchemy.Guild.role, snowflake`

  Receives the old role, the new role and the id of the guild that it belongs
  to. The old role may be `nil` if it was not already cached when the event
  was received.
  """
  defmacro on_role_update(func) do
    handle(:role_update, func)
  end

  @doc """
  Registers a handle triggering whenever a role gets deleted from a guild.

  `args` : `snowflake, snowflake`

  Receives the id of the role that was deleted, and the id of the guild it was
  deleted from.
  """
  defmacro on_role_delete(func) do
    handle(:role_delete, func)
  end

  @doc """
  Registers a handle triggering whenever a message gets sent.

  `args` : `Alchemy.Message.t`

  ### Examples

  ```elixir
  use Alchemy.Events

  Events.on_message(:ping)
  def ping(msg), do: IO.inspect msg.content
  ```
  """
  defmacro on_message(func) do
    handle(:message_create, func)
  end

  @doc """
  Registers a handle triggering whenever a message gets edited.

  `args` : `snowflake, snowflake`

  Receives the id of the message that was edited, and the channel it was
  edited in.
  """
  defmacro on_message_edit(func) do
    handle(:message_update, func)
  end

  @doc """
  Registers a handle triggering whenever a single message gets deleted.

  `args` : `snowflake, snowflake`

  Receives the id of the message that was deleted, and the channel it was deleted
  from.
  """
  defmacro on_message_delete(func) do
    handle(:message_delete, func)
  end

  @doc """
  Registers a handle triggering whenever messages get bulk deleted from a channel.

  `args` : `[snowflake], snowflake`

  Receives a list of message ids that were deleted, and the channel they were
  deleted from.
  """
  defmacro on_bulk_delete(func) do
    handle(:message_delete_bulk, func)
  end

  @doc """
  Registers a handle triggering whenever a user reacts to a message.

  `args` : `snowflake, snowflake, snowflake %{"animated" => boolean, "id" => integer, "name" => String.t}`

  Receives the id of the user that reacted, the channel_id where it happened, the message_id and the emoji
  """
  defmacro on_reaction_add(func) do
    handle(:message_reaction_add, func)
  end

  @doc """
  Registers a handle triggering whenever a user deletes a reaction to a message.

  `args` : `snowflake, snowflake, snowflake, %{"animated" => boolean, "id" => integer, "name" => String.t}`

  Receives the id of the user that reacted/deleted, the channel_id where it happened, the message_id and the emoji
  """
  defmacro on_reaction_remove(func) do
    handle(:message_reaction_remove, func)
  end

  @doc """
  Registere a handle triggering whenever a user deletes all reactions to a message.

  `args` : `snowflake, snowflake`

  Receives the channel_id and message_id
  """
  defmacro on_reaction_remove_all(func) do
    handle(:message_reaction_remove_all, func)
  end

  @doc """
  Registers a handle triggering whenever the presence of a user gets updated
  in a guild.

  `args` : `Alchemy.Presence.t`

  The presence struct here may be very incomplete.
  """
  defmacro on_presence_update(func) do
    handle(:presence_update, func)
  end

  @doc """
  Registers a handle triggering whenever a user starts typing in a channel.

  `args` : `snowflake, snowflake, Integer`

  Receives the id of the user, the channel, and a timestamp (unix seconds) of
  the typing event.
  """
  defmacro on_typing(func) do
    handle(:typing_start, func)
  end

  @doc """
  Registers a handle triggering whenever this user changes their settings.

  `args` : `String.t, String.t`

  Receives the username and avatar hash of the new settings.
  """
  defmacro on_settings_update(func) do
    handle(:user_settings_update, func)
  end

  @doc """
  Registers a handle triggering whenever this user changes.

  `args` : `Alchemy.User.t`

  Receives the new information for this user.
  """
  defmacro on_user_update(func) do
    handle(:user_update, func)
  end

  @doc """
  Registers a handle triggering whenever someone leaves / joins a voice
  channel.

  `args` : `Alchemy.Voice.state`

  Receives the corresponding voice state.
  """
  defmacro on_voice_update(func) do
    handle(:voice_state_update, func)
  end

  @doc """
  Registers a handle triggering whenever a shard receives a
  READY event.

  This event gets sent after a shard connects with the gateway,
  filling the cache with info about the guilds the bot is in.

  `args` : `Integer`, `Integer`
  Receives the shard number (starting at 0), and the total amount of shards.

  After this event has been received, most of the information in
  the cache should be failed.
  """
  defmacro on_ready(func) do
    handle(:ready, func)
  end

  @doc """
  Registers a handle triggering whenever a shard receives a member
  chunk.

  This event gets sent after a shard has requested offline guild
  member info for a guild.

  `args` : `snowflake`, `[Alchemy.Guild.GuildMember]`
  Receives the id of the guild the members are from, and a list
  of members loaded.
  """
  defmacro on_member_chunk(func) do
    handle(:member_chunk, func)
  end

  @doc false
  # Requires and aliases this module, as well as adds a @handles attribute,
  # necessary to use the other macros
  defmacro __using__(_opts) do
    quote do
      alias Alchemy.Events
      require Events

      @handles []

      @before_compile Events
    end
  end

  @doc false
  # For every handle in the attribute, a handler is added to the EventManager
  defmacro __before_compile__(_env) do
    quote do
      defmacro __using__(_opts) do
        for handle <- @handles do
          quote do
            Alchemy.Cogs.EventHandler.add_handler(unquote(handle))
          end
        end
      end
    end
  end

  @doc false
  # This is useful in a few places, converts "aliases" made here, into the internal
  # event
  def convert_type(type) do
    case type do
      :DM_channel_create -> :dm_channel_create
      :DM_channel_delete -> :dm_channel_delete
      :guild_join -> :guild_create
      :user_ban -> :guild_ban
      :user_unban -> :guild_unban
      :message_edit -> :message_update
      :bulk_delete -> :message_delete_bulk
      :typing -> :typing_start
      :settings_update -> :user_settings_update
      :voice_update -> :voice_state_update
      x -> x
    end
  end
end
