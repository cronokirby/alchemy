defmodule Alchemy.Cogs do
  alias Alchemy.Cogs.CommandHandler
  @moduledoc """
  This module provides quite a bit of sugar for registering commands.

  To use the macros in this module, it must be `used`. This also defines a
  `__using__` macro for that module, which will then allow these commands
  to be loaded in the main application via `use`

  ## Example Usage

  ```elixir
  defmodule Example do
    use Alchemy.Cogs

    Cogs.def ping, do: IO.inspect "pong!"

    Cogs.def echo do
      IO.inspect "please give me a word to echo"
    end
    Cogs.def echo("foo") do
      IO.inspect "foo are you?"
    end
    Cogs.def echo(word) do
      IO.inspect word
    end

  end
  """


  @doc """
  Sets the client's command prefix to a specific string.
  """
  @spec set_prefix(String.t) :: :ok
  def set_prefix(prefix) do
    CommandHandler.set_prefix(prefix)
  end

  @doc """
  Sends a message to the same channel as the message triggering a command.

  This can only be used in a command defined with `Cogs.def`

  ## Examples
  ```elixir
  Cogs.def ping, do: Cogs.say("pong!")
  ```
  """
  defmacro say(content, options \\ []) do
    quote do
      Alchemy.Client.send_message(var!(message).channel_id,
                                  unquote(content),
                                  unquote(options))
    end
  end
  @doc """
  Registers a new command, under the name of the function.

  This macro modifies the function definition, to accept an extra
  `message` parameter, allowing the message that triggered the command to be passed,
  as a `t:Alchemy.Message/0`
  ## Examples
  ```elixir
  Cogs.def ping do
    IO.inspect "pong"
  end
  ```

  In this case, "!ping" will trigger the command, unless another prefix has been set
  with `set_prefix/1`

  ```elixir
  Cogs.def mimic, do: IO.inspect "Please send a word for me to echo"
  Cogs.def mimic(word), do: IO.inspect word
  ```

  Messages will be parsed, and arguments will be extracted, however,
  to deal with potentially missing arguments, pattern matching should be used.
  So, in this case, when a 2nd argument isn't given, an error message is sent back.
  """
  defmacro def({name, ctx, args} = func, do: body) do
    args = case args do
      nil -> []
      some -> some
    end
    arity = length(args)
    arg_ctx = Keyword.get(ctx, :context)
    injected = [{:message, [], arg_ctx} | args]
    new_func = {:def, ctx, [{name, ctx, injected}, [do: body]]}
    quote do
      arity = unquote(arity)
      @commands update_in(@commands, [unquote(name)], fn
        nil ->
          {__MODULE__, arity}
        {mod, x} when x < arity ->
          {mod, arity}
        {mod, x, parser} when x < arity ->
          {mod, arity, parser}
        val ->
          val
      end)
      unquote(new_func)
    end
  end
  @doc """
  Allows you to register a custom message parser for a command.

  The parser will be applied to part of the message not used for command matching.
  ```elixir
  prefix <> command <> " " <> rest
  ```

  ## Examples
  ```elixir
  Cogs.set_parser(:echo, &List.wrap/1)
  Cogs.def echo(rest) do
    Cogs.say(rest)
  end
  ```
  """
  @type parser :: (String.t -> Enum.t)
  defmacro set_parser(name, parser) do
    quote do
      @commands update_in(@commands, [unquote(name)], fn
        nil ->
          {__MODULE__, 0, unquote(parser)}
        {mod, x} ->
          {mod, x, unquote(parser)}
        full ->
          full
      end)
    end
  end


  @doc false
  defmacro __using__(_opts) do
    quote do
      alias Alchemy.Cogs
      require Cogs

      @commands unquote(Macro.escape(%{}))

      @before_compile Cogs
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      defmacro __using__(_opts) do
        commands = Macro.escape(@commands)
        quote do
          Alchemy.Cogs.CommandHandler.add_commands(unquote(commands))
        end
      end
    end
  end


end
