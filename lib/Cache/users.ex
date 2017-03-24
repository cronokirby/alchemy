defmodule Alchemy.Cache.Users do
  @moduledoc false # Not to be confused with User.
  # This module serves to interface over an ets table storing user objects for easy
  # access, as well as the private channels related to them.
  use GenServer


  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end


  def init(:ok) do
    table = :ets.new(:users, [:named_table])
    {:ok, table}
  end
end
