defmodule Alchemy.Cache.Channels do
  # Simply used to keep a map from channel_id => guild_id
  @moduledoc false
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    {:ok, :ets.new(:channels, [:named_table])}
  end

  # unavailability does not get checked when this gets triggered
  def add_channels(nil, _) do
    nil
  end

  def add_channels(channels, guild_id) do
    GenServer.call(__MODULE__, {:add, channels, guild_id})
  end

  def remove_channel(id) do
    GenServer.call(__MODULE__, {:remove, id})
  end

  def handle_call({:add, channels, guild_id}, _, table) do
    for channel <- channels do
      :ets.insert(table, {channel["id"], guild_id})
    end

    {:reply, :ok, table}
  end

  def handle_call({:remove, id}, _, table) do
    :ets.delete(table, id)
    {:reply, :ok, table}
  end
end
