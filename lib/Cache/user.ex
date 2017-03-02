defmodule Alchemy.Cache.User do
  @moduledoc false # Serves as a cache for the user
  use GenServer


  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end


  def set_user(user) do
    GenServer.call(__MODULE__, {:set_user, user})
  end


  def handle_call({:set_user, user}, _, _state) do
    {:reply, :ok, user}
  end

end
