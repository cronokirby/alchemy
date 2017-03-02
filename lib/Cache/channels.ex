defmodule Alchemy.Cache.Channels do
  @moduledoc false # Simply used to keep a map from channel_id => guild_id
  use GenServer


  def start_link do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end


  # unavailability does not get checked when this gets triggered
  def add_channels(nil, _) do
    nil
  end
  def add_channels(channels, guild_id) do
    GenServer.call(__MODULE__, {:add, channels, guild_id})
  end


  def handle_call({:add, channels, guild_id}, _, state) do
    new_state = Enum.reduce(channels, state, fn channel, state ->
      Map.put(state, channel["id"], guild_id)
    end)
    {:reply, :ok, new_state}
  end

end
