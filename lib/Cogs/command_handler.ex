defmodule Alchemy.Cogs.CommandHandler do
  @moduledoc false
  require Logger
  use GenServer

  def add_commands(module, commands) do
    GenServer.call(__MODULE__, {:add_commands, module, commands})
  end

  def set_prefix(new) do
    GenServer.call(__MODULE__, {:set_prefix, new})
  end

  def unload(module) do
    GenServer.call(__MODULE__, {:unload, module})
  end

  def disable(func) do
    GenServer.call(__MODULE__, {:disable, func})
  end

  # Filters through a list of messages, trying to find a command
  def find_commands(events) do
    state = GenServer.call(__MODULE__, :copy)

    predicate =
      case state.options do
        [{:selfbot, id} | _] ->
          &(&1.author.id == id &&
              String.starts_with?(&1.content, state.prefix))

        _ ->
          &String.starts_with?(&1.content, state.prefix)
      end

    events
    |> Stream.filter(fn {_type, [message]} ->
      predicate.(message)
    end)
    |> Stream.map(fn {_type, [message]} ->
      get_command(message, state)
    end)
    |> Enum.filter(&(&1 != nil))
  end

  defp get_command(message, state) do
    prefix = state.prefix

    destructure(
      [_, command, rest],
      message.content
      |> String.split([prefix, " "], parts: 3)
      |> Enum.concat(["", ""])
    )

    case state[command] do
      {mod, arity, method} ->
        command_tuple(mod, method, arity, &String.split/1, message, rest)

      {mod, arity, method, parser} ->
        command_tuple(mod, method, arity, parser, message, rest)

      _ ->
        nil
    end
  end

  # Returns information about the command, ready to be run
  defp command_tuple(mod, method, arity, parser, message, content) do
    args = Enum.take(parser.(content), arity)
    {mod, method, [message | args]}
  end

  ### Server ###

  def start_link(options) do
    # String keys to avoid conflict with functions
    GenServer.start_link(__MODULE__, %{prefix: "!", options: options}, name: __MODULE__)
  end

  def handle_call(:list, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:unload, module}, _from, state) do
    new =
      Stream.filter(state, fn
        {_k, {^module, _, _}} -> false
        {_k, {^module, _}} -> false
        _ -> true
      end)
      |> Enum.into(%{})

    {:reply, :ok, new}
  end

  def handle_call({:disable, func}, _from, state) do
    {_pop, new} = Map.pop(state, func)
    {:reply, :ok, new}
  end

  def handle_call({:set_prefix, prefix}, _from, state) do
    {:reply, :ok, %{state | prefix: prefix}}
  end

  def handle_call({:add_commands, module, commands}, _from, state) do
    Logger.info("*#{inspect(module)}* loaded as a command cog")
    {:reply, :ok, Map.merge(state, commands)}
  end

  def handle_call(:copy, _from, state) do
    {:reply, state, state}
  end
end
