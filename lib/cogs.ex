defmodule Alchemy.Cogs do

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
      {_, new} = Map.get_and_update(@commands, unquote(name), fn val ->
        case val do
          nil -> {nil, {__MODULE__, arity}}
          {mod, x} when x < arity -> {val, {mod, arity}}
          val -> {val, val}
        end
      end)
      @commands new
      unquote(new_func)
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
