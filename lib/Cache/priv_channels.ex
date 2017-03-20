defmodule Alchemy.Cache.PrivChannels do
  @moduledoc false # This genserver keeps an internal ets table of private channels,
  # thus serving as the cache for them
  use GenServer


  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end


  def init(:ok) do
    table = :ets.new(:priv_channels, [:set, :protected])
    {:ok, table}
  end


  def add_channel(channel) do
    GenServer.call(__MODULE__, {:add, channel})
  end

  # Because we're using a set based table, inserting the entry will overwrite.
  def update_channel(channel) do
    GenServer.call(__MODULE__, {:add, channel})
  end


  def remove_channel(channel) do
    GenServer.call(__MODULE__, {:delete, channel})
  end


  def handle_call({:add, channel}, _from, table) do
     :ets.insert(table, {channel["id"], channel})
     {:reply, :ok, table}
  end

  def handle_call({:delete, channel}, _from, table) do
    :ets.delete(table, channel["id"])
    {:reply, :ok, table}
  end

end
