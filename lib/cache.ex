defmodule Alchemy.Cache do
  @moduledoc """
  This module provides a handful of useful functions to interact with the cache.

  By default, Alchemy caches a great deal of information given to it, notably about
  guilds. In general, using the cache should be prioritised over using the api
  functions in `Alchemy.Client`. However, a lot of struct modules have "smart"
  functions that will correctly balance the cache and the api, as well as use macros
  to get information from the context of commands.
  """
  alias Alchemy.Cache.Guilds
  alias Alchemy.Guild

  @type snowflake :: String.t
  @doc """
  Gets the corresponding guild_id for a channel.

  In case the channel guild can't be found, `:none` will be returned.

  This is useful when the guild_id is needed for some kind of task, but there's no
  need for getting the whole struct. Because of how the registry is set up, getting
  the entire guild requires a whole extra step, that passes through this one anyways.
  """
  @spec guild_id(snowflake) :: {:some, snowflake} | :none
  def guild_id(channel_id) do
    case :ets.lookup(:channels, channel_id) do
       [{_, id}] -> {:some, id}
       [] -> :none
    end
  end
  @doc """
  Fetches a guild from the cache by id.

  In general there are "smarter" methods, that will deal with getting the id for you;
  nonetheless, the need for this function sometimes exists.
  """
  @spec guild(snowflake) :: {:some, Guild.t} | :none
  def guild(guild_id) do
    Guilds.call(guild_id, :show)
    |> Guilds.de_index
    |> Guild.from_map
  end
  @doc """
  Gets the guild a channel belongs to.

  This is is equivalent to chaining `guild_id/1` and `guild/1`
  """
  @spec channel_guild(snowflake) :: {:some, Guild.t} | :none
  def channel_guild(channel_id) do
    with {:some, id} <- guild_id(channel_id) do
      guild(id)
    end
  end

end
