defmodule Alchemy.Voice.Supervisor do
  @moduledoc false
  # Supervises the voice section, including a registry and the dynamic
  # voice client supervisor.
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = [
      (supervisor(Registry, [:unique, __MODULE__.Registry]))
    ]

    supervise(children, strategy: :one_for_one)
  end

  defmodule Registry do
    def via(key) do
      {:via, Registry, {__MODULE__, key}}
    end
  end
end
