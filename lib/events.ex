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
  Adds a handler that will respond to any message by passing it to this function.

  `args` : `Alchemy.Message.t`

  This event gets triggered anytime a message gets sent.

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
