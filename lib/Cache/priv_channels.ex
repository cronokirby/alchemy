defmodule Alchemy.Cache.PrivChannels do
  # This genserver keeps an internal ets table of private channels,
  @moduledoc false
  # thus serving as the cache for them
  # This also keeps a mapping from recipient -> channel id
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    table = :ets.new(:priv_channels, [:named_table])
    {:ok, table}
  end

  def add_channel(channel) do
    GenServer.call(__MODULE__, {:add, channel})
  end

  # this is mainly used in the ready event
  def add_channels(channels) do
    GenServer.call(__MODULE__, {:add_list, channels})
  end

  # Because we're using a set based table, inserting the entry will overwrite.
  def update_channel(channel) do
    GenServer.call(__MODULE__, {:add, channel})
  end

  def remove_channel(channel) do
    GenServer.call(__MODULE__, {:delete, channel})
  end

  def handle_call({:add, channel}, _from, table) do
    %{"id" => id, "recipients" => [%{"id" => user_id} | _]} = channel
    :ets.insert(table, {id, channel})
    :ets.insert(table, {user_id, id})
    {:reply, :ok, table}
  end

  def handle_call({:add_list, channels}, _from, table) do
    Enum.each(channels, fn %{"id" => id, "recipients" => [%{"id" => user_id} | _]} = c ->
      :ets.insert(table, {id, c})
      :ets.insert(table, {user_id, id})
    end)

    {:reply, :ok, table}
  end

  def handle_call({:delete, channel}, _from, table) do
    :ets.delete(table, channel["id"])
    {:reply, :ok, table}
  end
end
