defmodule Alchemy.EventStage.StageSupervisor do
  @moduledoc false
  use Supervisor
  alias Alchemy.Cogs.{CommandHandler, EventHandler, EventRegistry}

  alias Alchemy.EventStage.{
    Cacher,
    EventBuffer,
    EventDispatcher,
    CommandStage,
    EventStage,
    Tasker
  }

  def start_link(command_options) do
    Supervisor.start_link(__MODULE__, command_options, name: __MODULE__)
  end

  @limit System.schedulers_online()

  def init(command_options) do
    cogs = [
      worker(CommandHandler, [command_options]),
      worker(EventHandler, []),
      worker(EventRegistry, [])
    ]

    stage1 = [worker(EventBuffer, [])]

    stage2 =
      for x <- 1..@limit do
        worker(Cacher, [x], id: x)
      end

    stage3_4 = [
      worker(EventDispatcher, [@limit]),
      worker(CommandStage, [@limit]),
      worker(EventStage, [@limit]),
      worker(Tasker, [])
    ]

    children = cogs ++ stage1 ++ stage2 ++ stage3_4
    supervise(children, strategy: :one_for_one)
  end
end
