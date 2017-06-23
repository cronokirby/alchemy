defmodule Alchemy.Voice.Macros do
  @moduledoc false

  defmacro simple_supervisor(modname, worker) do
    quote do
      defmodule unquote(modname) do
        use Supervisor

        def start_link do
          Supervisor.start_link(__MODULE__, :ok)
        end

        def init(:ok) do
          children = [
            worker(unquote(worker), [])
          ]

          supervise(children, strategy: :simple_one_for_one)
        end
      end
    end
  end

  defmacro __using__(_) do
    quote do
      import Alchemy.Voice.Macros
      require Alchemy.Voice.Macros
    end
  end
end
