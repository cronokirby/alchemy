defmodule Alchemy.Cogs.CommandHandler do
  @moduledoc false
  require Logger
  use GenServer


  def add_commands(module, commands) do
    GenServer.cast(Commands, {:add_commands, module, commands})
  end


  def set_prefix(new) do
    GenServer.cast(Commands, {:set_prefix, new})
  end


  def unload(module) do
    GenServer.call(Commands, {:unload, module})
  end


  def disable(func) do
    GenServer.call(Commands, {:disable, func})
  end


  def dispatch(message) do
    GenServer.cast(Commands, {:dispatch, message})
  end

  ### Server ###

  def start_link(options) do
    # String keys to avoid conflict with functions
    GenServer.start_link(__MODULE__, %{"prefix" => "!", "options" => options},
                         name: Commands)
  end


  def handle_call(:list, _from, state) do
    {:reply, state, state}
  end


  def handle_call({:unload, module}, _from, state) do
    new = Stream.filter(state, fn
      {_k, {^module, _, _}} -> false
      {_k, {^module, _}} -> false
      _ -> true
    end) |> Enum.into(%{})
    {:reply, :ok, new}
  end


  def handle_call({:disable, func}, _from, state) do
    {_pop, new} = Map.pop(state, func)
    {:reply, :ok, new}
  end


  def handle_cast({:set_prefix, prefix}, state) do
    {:noreply, %{state | "prefix" => prefix}}
  end


  def handle_cast({:add_commands, module, commands}, state) do
    Logger.info "*#{Macro.to_string module}* loaded as a command cog"
    {:noreply, Map.merge(state, commands)}
  end


  def handle_cast({:dispatch, message}, %{"options" => [selfbot: id]} = state) do
    if message.author.id == id do
      Task.start(fn -> dispatch(message, state) end)
    end
    {:noreply, state}
  end
  def handle_cast({:dispatch, message}, state) do
    Task.start(fn -> dispatch(message, state) end)
    {:noreply, state}
  end


  defp dispatch(message, state) do
     prefix = state["prefix"]
     destructure([_, command, rest],
                 message.content
                 |> String.split([prefix, " "], parts: 3)
                 |> Enum.concat(["", ""]))
     command = String.to_atom(command)
     case state[command] do
       {mod, arity} ->
         run_command(mod, command, arity, &String.split(&1), message, rest)
       {mod, arity, parser} ->
         run_command(mod, command, arity, parser, message, rest)
         _ -> nil
     end
  end

  defp run_command(mod, method, arity, parser, message, content) do
    args = Enum.take(parser.(content), arity)
    apply(mod, method, [message | args])
  end

end
