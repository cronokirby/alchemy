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
  require Alchemy.EventMacros
  import Alchemy.EventMacros
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

  `args` : `[Alchemy.Emoji.t], snowflake`

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

  `args` : `Alchemy.GuildMember.t, snowflake`

  Receives the member that was updated, and the guild they belong to.
  """
  defmacro on_member_update(func) do
    handle(:member_update, func)
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

end
