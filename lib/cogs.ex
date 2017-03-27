defmodule Alchemy.Cogs do
  @moduledoc """
  This module provides quite a bit of sugar for registering commands.

  To use the macros in this module, it must be `used`. This also defines a
  `__using__` macro for that module, which will then allow these commands
  to be loaded in the main application via `use`

  ## Example Usage

  ```elixir
  defmodule Example do
    use Alchemy.Cogs

    Cogs.def ping, do: Cogs.say "pong!"

    Cogs.def echo do
      Cogs.say "please give me a word to echo"
    end
    Cogs.def echo("foo") do
      Cogs.say "foo are you?"
    end
    Cogs.def echo(word) do
      Cogs.say word
    end

  end
  """
  alias Alchemy.Cogs.CommandHandler
  alias Alchemy.Embed
  alias Alchemy.Cache


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

  This is just a thin macro around `Alchemy.Client.send_message/2`

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
  """
  defmacro send(embed, content \\ "") do
    quote do
      Alchemy.Client.send_message(var!(message).channel_id,
                                  unquote(content),
                                  embed: unquote(embed))
    end
  end
  @doc """
  Gets the id of the guild from which a command was triggered.

  This is to be used when the guild_id is necessary for an operation,
  but the fuill guild struct isn't needed.
  """
  defmacro guild_id do
    quote do
      Cache.guild_id(var!(message).channel_id)
    end
  end
  @doc """
  Gets the guild struct from which a command was triggered.

  If only the id is needed, see `:guild_id/0`

  ## Examples
  ```elixir
  Cogs.def guild do
    {:ok, %Alchemy.Guild{name: name}} = Cogs.guild()
    Cogs.say(name)
  end
  ```
  """
  defmacro guild do
    quote do
      Cache.guild(channel: var!(message).channel_id)
    end
  end
  @doc """
  Gets the member that triggered a command.

  As opposed to `message.author`, this comes with a bit more info about who
  triggered the command. This is useful for when you want to use certain information
  in a command, such as permissions, for example.
  """
  defmacro member do
    quote do
      {:ok, cCcCc} = Cache.guild_id(var!(message).channel_id)
      Cache.member(cCcCc, var!(message).author.id)
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
    Cogs.say "pong"
  end
  ```

  In this case, "!ping" will trigger the command, unless another prefix has been set
  with `set_prefix/1`

  ```elixir
  Cogs.def mimic, do: Cogs.say "Please send a word for me to echo"
  Cogs.def mimic(word), do: Cogs.say word
  ```

  Messages will be parsed, and arguments will be extracted, however,
  to deal with potentially missing arguments, pattern matching should be used.
  So, in this case, when a 2nd argument isn't given, an error message is sent back.
  """
  defmacro def({name, ctx, args} = func, do: body) do
    args = args || []
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
    parser = Macro.to_string(parser)
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
        module = __MODULE__
        quote do
          Alchemy.Cogs.CommandHandler.add_commands(unquote(module),
            unquote(commands) |> Enum.map(fn
              {k, {mod, arity, string}} ->
                {eval, _} = Code.eval_string(string)
                {k, {mod, arity, eval}}
              {k, v} ->
                {k, v}
            end)
            |> Enum.into(%{}))
        end
      end
    end
  end


end
