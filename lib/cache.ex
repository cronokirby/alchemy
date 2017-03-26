defmodule Alchemy.Cache do
  @moduledoc """
  This module provides a handful of useful functions to interact with the cache.

  By default, Alchemy caches a great deal of information given to it, notably about
  guilds. In general, using the cache should be prioritised over using the api
  functions in `Alchemy.Client`. However, a lot of struct modules have "smart"
  functions that will correctly balance the cache and the api, as well as use macros
  to get information from the context of commands.
  """
  alias Alchemy.Cache.{Guilds, Guilds.GuildSupervisor}
  alias Alchemy.{DMChannel, Emoji, Guild, GuildMember, Role, Users.Presence}
  import Alchemy.Structs, only: [to_struct: 2]

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


  # Returns the corresponding protocol for an atom key.
  # This is mainly needed for `search/2`
  defp cache_sections(key) do
    %{members: {"members", &GuildMember.from_map/1},
      roles: {"roles", &to_struct(&1, Role)},
      presences: {"presences", &Presence.from_map/1},
      voice_states: {"voice_states", &to_struct(&1, VoiceState)},
      emojis: {"emojis", &to_struct(&1, Emoji)}}[key]
  end
  @doc """
  Searches across all guild for information.

  The section is the type of object to search for. The possibilities are:
  `:guilds`, `:members`, `:roles`, `:presences`, `:voice_states`, `:emojis`,
  `:channels`

  The filter is a function returning a boolean, that allows you to filter out
  elements from this list.

  The return type will be a struct of the same type of the section searched for.
  ## Examples
  ```elixir
  Cache.search(:members, fn x -> String.length(x.nick) < 10 end)
  ```
  This will return a list of all members whose nickname is less than 10
  characters long.
  ```elixir
  Cache.search(:roles, &match?(%{name: "Cool Kids"}, &1))
  ```
  This is a good example of using the `match?/2`
  function to filter against a pattern.
  ```elixir
  Cache.search(:guilds, &match?(%{name: "Test"}, &1))
  ```
  Will match any guilds named "Test" in the cache.
  """
  @spec search(atom, (any -> Boolean)) :: [struct]
  def search(:guilds, filter) do
    Supervisor.which_children(GuildSupervisor)
    |> Stream.map(fn {_, pid, _, _} -> pid end)
    |> Task.async_stream(&GenServer.call(&1, :show))
    |> Stream.map(fn {:ok, val} ->
      val |> Guilds.de_index |> Guild.from_map
    end)
    |> Enum.filter(filter)
  end
  def search(:private_channels, filter) do
    fold = fn {id, val}, acc ->
      if filter.(val) do [val | acc] else acc end
    end
    :ets.foldr(fold, [], :priv_channels)
  end
  def search(section, filter) do
    {key, de_indexer} = cache_sections(section)
     Supervisor.which_children(GuildSupervisor)
     |> Stream.map(fn {_, pid, _, _} -> pid end)
     |> Task.async_stream(&GenServer.call(&1, {:section, key}))
     |> Stream.flat_map(fn {:ok, v} -> Map.values(v) end)
     |> Stream.map(de_indexer)
     |> Enum.filter(filter)
  end
  @doc """
  Fetches a private_channel in the cache by id of the channel.

  Takes a DMChannel id. Alternatively, `user: user_id` can be passed to find
  the private channel related to a user.
  """
  @spec private_channel(snowflake) :: {:ok, Channel.dm_channel} | {:error, String.t}
  def private_channel(user: user_id) do
    case :ets.lookup(:priv_channels, user_id) do
      [{_, id}] -> private_channel(id)
      [] -> {:error, "Failed to find a DM channel for this user: #{user_id}"}
    end
  end
  def private_channel(channel_id) do
    case :ets.lookup(:priv_channels, channel_id) do
       [{_, channel}] -> {:ok, DMChannel.from_map(channel)}
       [] ->  {:error, "Failed to find a DM channel entry for #{channel_id}."}
    end
  end
end
