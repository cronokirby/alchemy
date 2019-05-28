defmodule Alchemy.Cogs do
  alias Alchemy.Cache
  alias Alchemy.Cogs.CommandHandler
  alias Alchemy.Cogs.EventRegistry
  alias Alchemy.Events
  alias Alchemy.Guild
  require Logger

  @moduledoc """
  This module provides quite a bit of sugar for registering commands.

  To use the macros in this module, it must be `used`. This also defines a
  `__using__` macro for that module, which will then allow these commands
  to be loaded in the main application via `use`

  ## Example Module
  ```elixir
  defmodule Example do
    use Alchemy.Cogs

    Cogs.def ping do
      Cogs.say "pong"
    end

    Cogs.def echo do
      Cogs.say "please give me a word to echo"
    end
    Cogs.def echo(word) do
      Cogs.say word
    end
  end
  ```
  This defines a basic Cog, that can now be loaded into our application via `use`.
  The command created from this module are "!ping", and "!echo",
  ("!" is merely the default prefix, it could be anything from "?", to "SHARKNADO").
  The `ping` command is straight forward, but as you can see, the `echo` command
  takes in an argument. When you define a command, the handler will
  try and get arguments up to the max arity of that command;
  in this case, `echo` has a max arity of one, so the parser will pass up to
  one argument to the function. In the case that the parser can't get enough
  arguments, it will pass a lower amount. We explicitly handle this case
  here, in this case sending a useful error message back.

  ### Shared names across multiple modules
  If I define a command `ping` in module `A`, and a `ping` in module `B`,
  which `ping` should become the command? In general, you should avoid doing
  this, but the module used last will override previously loaded commands
  with a matching name.


  ## Parsing
  The way the parser works is simple: a message is first decomposed into
  parts:
  ```
  prefix <> command <> " " <> rest
  ```
  If the prefix doesn't match, the message is ignored. If it does match,
  a new Task is started to handle this event. This task will try and find
  the function corresponding to the command called, and will return preemptively
  if no such function is found. After that, `rest` is passed to the parser,
  which will try and extract arguments to pass to the function. The default
  parsing method is simply splitting by whitespace.
  Thankfully,
  you can define a custom parser for a command via `Cogs.set_parser/2`. This
  parser will act upon `rest`, and parse out the relevant arguments.

  ## The `message` argument
  When you define a function with `Cogs.def` the function gets expanded
  to take an extra `message` parameter, which is the message triggering
  the command. This contains a lot of useful information, and is what
  enables a lot of the other macros to work. Because of this,
  be wary of naming something else `message`.

  ## Loading and Unloading

  Loading a cog merely requires having started the client:
  ```elixir
  use Example
  ```
  If you need to remove this cog from the handler:
  ```elixir
  Cogs.unload(Example)
  ```
  Or you just want to disable a single function:
  ```elixir
  Cogs.disable(:ping)
  ```
  """

  @doc """
  Sets the client's command prefix to a specific string.

  This will only work after the client has been started
  # Example
  ```elixir
  Client.start(@token)
  Cogs.set_prefix("!!")
  ```
  """
  @spec set_prefix(String.t()) :: :ok
  def set_prefix(prefix) do
    CommandHandler.set_prefix(prefix)
  end

  @doc """
  Unloads a module from the handler.

  If you just want to disable a single command, use `Cogs.disable/1`

  ## Examples
  ```elixir
  Client.start(@token)
  use Commands2
  ```
  Turns out we want to stop using `Commands2` commands in our bot, so we
  can simply unload the module:
  ```elixir
  Cogs.unload(Commands2)
  ```
  Now none of the commands defined in that module will be accessible. If
  we want to reverse that, we can merely do:
  ```elixir
  use Commands2
  ```
  and reload them back in.
  """
  @spec unload(atom) :: :ok
  def unload(module) do
    CommandHandler.unload(module)
    Logger.info("*#{inspect(module)}* unloaded from cogs")
  end

  @doc """
  Disables a command.

  If you want to remove a whole module from the cogs, use `Cogs.unload/1`.

  This will stop a command from being triggered. The only way to reenable the
  command is to reload the module with `use`.
  ## Examples
  ```elixir
  defmodule Example do
    use Alchemy.Cogs

    Cogs.def ping, do: Cogs.say "pong"

    Cogs.def foo, do: Cogs.say "bar"
  end
  ```
  ```elixir
  Client.start(@token)
  use Example
  Cogs.disable(:foo)
  ```
  Only `ping` will be triggerable now.
  ```elixir
  use Example
  ```
  At runtime this will add `foo` back in, given it's still in the module.
  """
  @spec disable(atom) :: :ok
  def disable(command) do
    CommandHandler.disable(command)
    Logger.info("Command *#{command}* disabled")
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
      Alchemy.Client.send_message(
        var!(message).channel_id,
        unquote(content),
        unquote(options)
      )
    end
  end

  @doc """
  Gets the id of the guild from which a command was triggered.

  Returns `{:ok, id}`, or `{:error, why}`. Will never return ok outside
  of a guild, naturally.
  This is to be used when the guild_id is necessary for an operation,
  but the full guild struct isn't needed.
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

  Returns either `{:ok, member}`, or `{:error, why}`. Will not return
  ok if the command wasn't run in a guild.
  As opposed to `message.author`, this comes with a bit more info about who
  triggered the command. This is useful for when you want to use certain information
  in a command, such as permissions, for example.
  """
  defmacro member do
    quote do
      with {:ok, guild} <- Cache.guild_id(var!(message).channel_id) do
        Cache.member(guild, var!(message).author.id)
      end
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
  @type parser :: (String.t() -> Enum.t())
  defmacro set_parser(name, parser) do
    parser = Macro.escape(parser)

    quote do
      @commands update_in(@commands, [Atom.to_string(unquote(name))], fn
                  nil ->
                    {__MODULE__, 0, unquote(name), unquote(parser)}

                  {mod, x, name} ->
                    {mod, x, name, unquote(parser)}

                  full ->
                    full
                end)
    end
  end

  @doc """
  Makes all commands in this module sub commands of a group.

  ## Examples
  ```elixir
  defmodule C do
    use Alchemy.Cogs

    Cogs.group("cool")

    Cogs.def foo, do: Cogs.say "foo"
  end
  ```
  To use this foo command, one has to type `!cool foo`, from there on
  arguments will be passed like normal.

  The relevant parsing will be done in the command task, as if there
  were a command `!cool` that redirected to subfunctions. Because of this,
  `Cogs.disable/1` will not be able to disable the subcommands, however,
  `Cogs.unload/1` still works as expected. Reloading a grouped module
  will also disable removed commands, unlike with ungrouped modules.
  """
  defmacro group(str) do
    quote do
      @command_group {:group, unquote(str)}
    end
  end

  @doc """
  Halts the current command until an event is received.

  The event type is an item corresponding to the events in `Alchemy.Events`,
  i.e. `on_message_edit` -> `Cogs.wait_for(:message_edit, ...)`. The `fun`
  is the function that gets called with the relevant event arguments; see
  `Alchemy.Events` for more info on what events have what arguments.

  The `:message` event is a bit special, as it will specifically wait for
  a message not triggered by a bot, in that specific channel, unlike other events,
  which trigger generically across the entire bot.

  The process will kill itself if it doesn't receive any such event
  for 20s.
  ## Examples
  ```elixir
  Cogs.def color do
    Cogs.say "What's your favorite color?"
    Cogs.wait_for :message, fn msg ->
      Cogs.say "\#{msg.content} is my favorite color too!"
    end
  end
  ```
  ```elixir
  Cogs.def typing do
    Cogs.say "I'm waiting for someone to type.."
    Cogs.wait_for :typing, fn _,_,_ ->
      Cogs.say "Someone somewhere started typing..."
    end
  ```
  """
  # messages need special treatment, to ignore bots
  defmacro wait_for(:message, fun) do
    quote do
      EventRegistry.subscribe()
      channel = var!(message).channel_id

      receive do
        {:discord_event,
         {:message_create, [%{author: %{bot: false}, channel_id: ^channel}] = args}} ->
          apply(unquote(fun), args)
      after
        20_000 -> Process.exit(self(), :kill)
      end
    end
  end

  defmacro wait_for(type, fun) do
    # convert the special cases we set in the Events module
    type = Events.convert_type(type)

    quote do
      EventRegistry.subscribe()

      receive do
        {:discord_event, {unquote(type), args}} ->
          apply(unquote(fun), args)
      after
        20_000 -> Process.exit(self(), :kill)
      end
    end
  end

  @doc """
  Waits for a specific event satisfying a condition.

  Same as `wait_for/2`, except this takes an extra condition that needs to be
  met for the waiting to handle to trigger.
  ## Examples
  ```elixir
  Cogs.def foo do
    Cogs.say "Send me foo"
    Cogs.wait_for(:message, & &1.content == "foo", fn _msg ->
      Cogs.say "Nice foo man!"
    end)
  ```
  Note that, if no event of the given type is received after 20s, the process
  will kill itself, it's possible that this will never get met, but
  no event satisfying the condition will ever arrive, essentially rendering
  the process a waste. To circumvent this, it might be smart to send
  a preemptive kill message:
  ```elixir
  self = self()
  Task.start(fn ->
    Process.sleep(20_000)
    Process.exit(self, :kill)
  )
  Cogs.wait_for(:message, fn x -> false end, fn _msg ->
    Cogs.say "If you hear this, logic itself is falling apart!!!"
  end)
  ```
  """
  defmacro wait_for(:message, condition, fun) do
    m = __MODULE__

    quote do
      EventRegistry.subscribe()
      unquote(m).wait(:message, unquote(condition), unquote(fun), var!(message).channel_id)
    end
  end

  defmacro wait_for(type, condition, fun) do
    type = Events.convert_type(type)
    m = __MODULE__

    quote do
      EventRegistry.subscribe()
      unquote(m).wait(unquote(type), unquote(condition), unquote(fun))
    end
  end

  # Loops until the correct command is received
  @doc false
  def wait(:message, condition, fun, channel_id) do
    receive do
      {:discord_event,
       {:message_create, [%{author: %{bot: false}, channel_id: ^channel_id}] = args}} ->
        if apply(condition, args) do
          apply(fun, args)
        else
          wait(:message, condition, fun, channel_id)
        end
    after
      20_000 -> Process.exit(self(), :kill)
    end
  end

  @doc false
  def wait(type, condition, fun) do
    receive do
      {:discord_event, {^type, args}} ->
        if apply(condition, args) do
          apply(fun, args)
        else
          wait(type, condition, fun)
        end
    after
      20_000 -> Process.exit(self(), :kill)
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
  defmacro def(func, body) do
    {name, arity, new_func} = inject(func, body)

    quote do
      arity = unquote(arity)

      @commands update_in(@commands, [Atom.to_string(unquote(name))], fn
                  nil ->
                    {__MODULE__, arity, unquote(name)}

                  {mod, x, name} when x < arity ->
                    {mod, arity, name}

                  {mod, x, name, parser} when x < arity ->
                    {mod, arity, name, parser}

                  val ->
                    val
                end)
      unquote(new_func)
    end
  end

  defp inject({:when, ctx, [{name, _, args} | func_rest]} = guard, body) do
    args = args || []
    injected = [{:message, [], ctx[:context]} | args]

    new_guard =
      Macro.prewalk(guard, fn {a, b, _} ->
        {a, b, [{name, ctx, injected} | func_rest]}
      end)

    new_func = {:def, ctx, [new_guard, body]}
    {name, length(args), new_func}
  end

  defp inject({name, ctx, args}, body) do
    args = args || []
    injected = [{:message, [], ctx[:context]} | args]
    new_func = {:def, ctx, [{name, ctx, injected}, body]}
    {name, length(args), new_func}
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

  defp normal_cog do
    quote do
      defmacro __using__(_opts) do
        commands = Macro.escape(@commands)
        module = __MODULE__

        quote do
          Alchemy.Cogs.CommandHandler.add_commands(
            unquote(module),
            unquote(commands)
            |> Enum.map(fn
              {k, {mod, arity, name, quoted}} ->
                {eval, _} = Code.eval_quoted(quoted)
                {k, {mod, arity, name, eval}}

              {k, v} ->
                {k, v}
            end)
            |> Enum.into(%{})
          )
        end
      end
    end
  end

  defp grouped_cog(str, commands) do
    quote do
      def cOGS_COMMANDS_GROUPER(message, rest) do
        [sub, rest] =
          rest
          |> String.split(" ", parts: 2)
          |> Enum.concat([""])
          |> Enum.take(2)

        case unquote(commands)[sub] do
          {m, a, f, e} ->
            apply(m, f, [message | rest |> e.() |> Enum.take(a)])

          {m, a, f} ->
            apply(m, f, [message | rest |> String.split() |> Enum.take(a)])

          _x ->
            nil
        end
      end

      defmacro __using__(_opts) do
        module = __MODULE__

        commands =
          %{unquote(str) => {module, 1, :cOGS_COMMANDS_GROUPER, &List.wrap/1}}
          |> Macro.escape()

        quote do
          Alchemy.Cogs.CommandHandler.add_commands(
            unquote(module),
            unquote(commands)
          )
        end
      end
    end
  end

  defmacro __before_compile__(env) do
    module = env.module

    case Module.get_attribute(module, :command_group) do
      {:group, str} ->
        # Replace the map with the AST representing it, keeping the lambdas
        commands =
          Module.get_attribute(module, :commands)
          |> Enum.map(fn {k, v} ->
            {k, {:{}, [], Tuple.to_list(v)}}
          end)

        grouped_cog(str, {:%{}, [], commands})

      nil ->
        normal_cog()
    end
  end

  @doc """
  Returns a map from command name (string) to the command information.

  Each command is either `{module, arity, function_name}`, or 
  `{module, arity, function_name, parser}`.

  This can be useful for providing some kind of help command, or telling
  a user if a command is defined, e.g. :
  ```elixir
  Cogs.def iscommand(maybe) do
    case Cogs.all_commands()[maybe] do
      nil -> Cogs.say "\#{maybe} is not a command"
      _   -> Cogs.say "\#{maybe} is a command"
    end
  end
  ```
  """
  @spec all_commands :: map
  def all_commands do
    GenServer.call(Alchemy.Cogs.CommandHandler, :list)
    |> Map.delete(:prefix)
    |> Map.delete(:options)
  end

  @doc """
  Returns the base permissions for a member in a guild.

  Functions similarly to `permissions`.
  """
  defmacro guild_permissions do
    quote do
      with {:ok, guild} <- Cache.guild(channel: var!(message).channel_id),
           {:ok, member} <- Cache.member(guild.id, var!(message).author.id) do
        {:ok, Alchemy.Guild.highest_role(guild, member).permissions}
      end
    end
  end

  @doc """
  Returns the permission bitset of the current member in the channel the command
  was called from.

  If you just want the base permissions of the member in the guild, 
  see `guild_permissions`.
  Returns `{:ok, perms}`, or `{:error, why}`. Fails if not called from
  a guild, or the guild or the member couldn't be fetched from the cache.
  ## Example
  ```elixir
  Cogs.def perms do
    with {:ok, permissions} <- Cogs.permissions() do
      Cogs.say "Here's a list of your permissions `\#{Permissions.to_list(permissions)}`"
    end
  end
  ```
  """
  defmacro permissions do
    quote do
      with {:ok, guild} <- Cache.guild(channel: var!(message).channel_id),
           {:ok, member} <- Cache.member(guild.id, var!(message).author.id) do
        Alchemy.Permissions.channel_permissions(member, guild, var!(message).channel_id)
      end
    end
  end
end
