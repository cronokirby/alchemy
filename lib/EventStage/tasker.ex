defmodule Alchemy.EventStage.Tasker do
  # Serves as the final stage, recieving
  @moduledoc false
  # functions and commands to run in new tasks
  use ConsumerSupervisor
  alias Alchemy.EventStage.{CommandStage, EventStage}

  defmodule Runner do
    @moduledoc false
    def start_link({m, f, a}) do
      Task.start_link(m, f, a)
    end
  end

  def start_link do
    ConsumerSupervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    children = [worker(Runner, [], restart: :temporary)]
    producers = [CommandStage, EventStage]
    {:ok, children, strategy: :one_for_one, subscribe_to: producers}
  end
end
