defmodule Alchemy.EventStage.Cacher do
  # This stage serves to update the cache
  @moduledoc false
  # before passing events on.
  # To leverage the concurrent cache, this module
  # is intended to be duplicated for each scheduler.
  # After that, it broadcasts split over the command and event dispatcher
  use GenStage
  require Logger
  alias Alchemy.EventStage.EventBuffer
  alias Alchemy.Discord.Events

  # Each of the instances gets a specific id
  def start_link(id) do
    name = Module.concat(__MODULE__, :"#{id}")
    GenStage.start_link(__MODULE__, :ok, name: name)
  end

  def init(:ok) do
    # no state to keep track of, subscribe to the event source
    {:producer_consumer, :ok,
     [subscribe_to: [EventBuffer], dispatcher: GenStage.BroadcastDispatcher]}
  end

  def handle_events(events, _from, state) do
    # I think that using async_stream here would be redundant,
    # as we're already duplicating this stage. This might warrant future
    # testing, and would be an easy change to implement
    cached =
      Enum.map(events, fn {type, payload} ->
        handle_event(type, payload)
      end)

    {:noreply, cached, state}
  end

  defp handle_event(type, %{"guild_id" => guild_id} = payload) when is_binary(guild_id) do
    
    # This is to handle possible calls for a guild
    # which has not been registered yet.
    #
    # This can happen when a bot joins a guild
    # and at the same time any member gets updated - new username, new role assigned etc.
    #
    # We will receive the signals GUILD_MEMBER_UPDATE & GUILD_CREATE simultaneously.
    #
    # If the GUILD_MEMBER_UPDATE signal gets processed before the GUILD_CREATE
    # the Cache will crash as no genserver with the given guild id exists in the 
    # Registry yet. 
    if Registry.lookup(:guilds, guild_id) != [] do  
        Events.handle(type, payload)
    else
        Logger.debug("Not handling #{inspect(type)} for #{guild_id} as the guild has not been started yet. Payload was #{inspect(payload)}")
      {:unkown, []}
    end
  end

  defp handle_event(type, payload) do
    Events.handle(type, payload)
  end

end
