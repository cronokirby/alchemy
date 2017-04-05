defmodule Alchemy.Cogs.CogSupervisor do
  @moduledoc false
  # Acts as the supervisor for the command handler, event handler,
  # and event registry
  alias Alchemy.Cogs.{CommandHandler, EventHandler, EventRegistry}
  use Supervisor


  def start_link(command_options) do
    Supervisor.start_link(__MODULE__, {:ops, command_options}, name: __MODULE__)
  end

  def init({:ops, command_options}) do
    children = [
      supervisor(EventRegistry, []),
      worker(CommandHandler, [command_options]),
      worker(EventHandler, [])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
