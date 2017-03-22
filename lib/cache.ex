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
  alias Alchemy.{Emoji, Guild, GuildMember, Role, Users.Presence}


  @type snowflake :: String.t
  @doc """
  Gets the corresponding guild_id for a channel.

  In case the channel guild can't be found, `:none` will be returned.

  This is useful when the guild_id is needed for some kind of task, but there's no
  need for getting the whole struct. Because of how the registry is set up, getting
  the entire guild requires a whole extra step, that passes through this one anyways.
  """
  @spec guild_id(snowflake) :: {:ok, snowflake} | {:error, String.t}
  def guild_id(channel_id) do
    case :ets.lookup(:channels, channel_id) do
       [{_, id}] -> {:ok, id}
       [] ->  {:error, "Failed to find a channel entry for #{channel_id}."}
    end
  end
  @doc """
  Fetches a guild from the cache by a given id.

  By default, this method needs the guild_id, but keywords can be used to specify
  a different id, and use the appropiate paths to get the guild using that.

  In general there are "smarter" methods, that will deal with getting the id for you;
  nonetheless, the need for this function sometimes exists.

  ## Keywords
  - `channel`
    Using this keyword will fetch the information for the guild a channel belongs to.
  """
  @spec guild(snowflake) :: {:ok, Guild.t} | {:error, String.t}
  def guild(channel: channel_id) do
    with {:ok, id} <- guild_id(channel_id) do
      guild(id)
    end
  end
  def guild(guild_id) do
    g = Guilds.call(guild_id, :show)
        |> Guilds.de_index
        |> Guild.from_map
    {:ok, g}
  end



  defp access(guild_id, section, id, module) do
    maybe_val =
      guild_id
      |> Guilds.call({:section, section})
      |> get_in([id])
    case maybe_val do
      nil ->
        {:error, "Failed to find an entry for #{id} in section #{section}"}
      some ->
        {:ok, module.from_map(some)}
    end
  end
  @doc """
  Gets a member from a cache, by guild and member id.
  """
  @spec member(snowflake, snowflake) :: {:ok, GuildMember.t} | {:error, String.t}
  def member(guild_id, member_id) do
    access(guild_id, "members", member_id, GuildMember)
  end
  @doc """
  Gets a specific role in a guild.
  """
  @spec role(snowflake, snowflake) :: {:ok, Role.t} | {:error, String.t}
  def role(guild_id, role_id) do
    access(guild_id, "roles", role_id, Role)
  end
  @doc """
  Gets the presence of a user in a certain guild.

  This contains info such as their status, and roles.
  """
  @spec presence(snowflake, snowflake) :: {:ok, Presence.t} | {:error, String.t}
  def presence(guild_id, user_id) do
    access(guild_id, "presences", user_id, Presence)
  end
  @doc """
  Retrieves a custom emoji by id in a guild.
  """
  @spec emoji(snowflake, snowflake) :: {:ok, Emoji.t} | {:error, String.t}
  def emoji(guild_id, emoji_id) do
    access(guild_id, "emojis", emoji_id, Emoji)
  end
end
