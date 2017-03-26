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
  Registers a handle triggering whenever a guild channel gets updated.

  `args` : Alchemy.Channel.t
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
