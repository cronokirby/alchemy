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
  alias Alchemy.{Channel.DMChannel, Channel, Guild, User, VoiceState, Voice}
  alias Alchemy.Guild.{Emoji, GuildMember, Presence, Role}
  alias Alchemy.Discord.Gateway.RateLimiter, as: Gateway
  import Alchemy.Structs, only: [to_struct: 2]

  @type snowflake :: String.t()
  @doc """
  Gets the corresponding guild_id for a channel.

  In case the channel guild can't be found, `:none` will be returned.

  This is useful when the guild_id is needed for some kind of task, but there's no
  need for getting the whole struct. Because of how the registry is set up, getting
  the entire guild requires a whole extra step, that passes through this one anyways.
  """
  @spec guild_id(snowflake) :: {:ok, snowflake} | {:error, String.t()}
  def guild_id(channel_id) do
    case :ets.lookup(:channels, channel_id) do
      [{_, id}] -> {:ok, id}
      [] -> {:error, "Failed to find a channel entry for #{channel_id}."}
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
  @spec guild(snowflake) :: {:ok, Guild.t()} | {:error, String.t()}
  def guild(channel: channel_id) do
    with {:ok, id} <- guild_id(channel_id) do
      guild(id)
    end
  end

  def guild(guild_id) do
    case Guilds.safe_call(guild_id, :show) do
      {:error, :no_guild} ->
        {:error, "You don't seem to be in this guild"}

      {:ok, %{"unavailable" => true}} ->
        {:error, "This guild hasn't been loaded in the cache yet"}

      {:ok, guild} ->
        {:ok, guild |> Guilds.de_index() |> Guild.from_map()}
    end
  end

  defp access(guild_id, section, id, module) when is_atom(module) do
    access(guild_id, section, id, &module.from_map/1)
  end

  defp access(guild_id, section, id, function) do
    maybe_val =
      with {:ok, guild} <- Guilds.safe_call(guild_id, {:section, section}) do
        {:ok, guild[id]}
      end

    case maybe_val do
      {:error, :no_guild} ->
        {:error, "You don't seem to be in this guild"}

      {:ok, nil} ->
        {:error, "Failed to find an entry for #{id} in section #{section}"}

      {:ok, some} ->
        {:ok, function.(some)}
    end
  end

  @doc """
  Gets a member from a cache, by guild and member id.
  """
  @spec member(snowflake, snowflake) :: {:ok, Guild.member()} | {:error, String.t()}
  def member(guild_id, member_id) do
    access(guild_id, "members", member_id, GuildMember)
  end

  @doc """
  Gets a specific role in a guild.
  """
  @spec role(snowflake, snowflake) :: {:ok, Guild.role()} | {:error, String.t()}
  def role(guild_id, role_id) do
    access(guild_id, "roles", role_id, &to_struct(&1, Role))
  end

  @doc """
  Gets the presence of a user in a certain guild.

  This contains info such as their status, and roles.
  """
  @spec presence(snowflake, snowflake) :: {:ok, Presence.t()} | {:error, String.t()}
  def presence(guild_id, user_id) do
    access(guild_id, "presences", user_id, Presence)
  end

  @doc """
  Retrieves a custom emoji by id in a guild.
  """
  @spec emoji(snowflake, snowflake) :: {:ok, Guild.emoji()} | {:error, String.t()}
  def emoji(guild_id, emoji_id) do
    access(guild_id, "emojis", emoji_id, &to_struct(&1, Emoji))
  end

  @doc """
  Retrieves a user's voice state by id in a guild.
  """
  @spec voice_state(snowflake, snowflake) :: {:ok, Voice.state()} | {:error, String.t()}
  def voice_state(guild_id, user_id) do
    access(guild_id, "voice_states", user_id, &to_struct(&1, VoiceState))
  end

  @doc """
  Retrieves a specific channel in a guild.
  """
  @spec channel(snowflake, snowflake) :: {:ok, Channel.t()} | {:error, String.t()}
  def channel(guild_id, channel_id) do
    access(guild_id, "channels", channel_id, Channel)
  end

  # Returns the corresponding protocol for an atom key.
  # This is mainly needed for `search/2`
  defp cache_sections(key) do
    %{
      members: {"members", &GuildMember.from_map/1},
      roles: {"roles", &to_struct(&1, Role)},
      presences: {"presences", &Presence.from_map/1},
      voice_states: {"voice_states", &to_struct(&1, VoiceState)},
      emojis: {"emojis", &to_struct(&1, Emoji)},
      channels: {"channels", &Channel.from_map/1}
    }[key]
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
    |> Stream.filter(fn {:ok, val} ->
      val["unavailable"] != true
    end)
    |> Stream.map(fn {:ok, val} ->
      val |> Guilds.de_index() |> Guild.from_map()
    end)
    |> Enum.filter(filter)
  end

  def search(:private_channels, filter) do
    fold = fn {_id, val}, acc ->
      if filter.(val) do
        [val | acc]
      else
        acc
      end
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
  @spec private_channel(snowflake) :: {:ok, Channel.dm_channel()} | {:error, String.t()}
  def private_channel(user: user_id) do
    case :ets.lookup(:priv_channels, user_id) do
      [{_, id}] -> private_channel(id)
      [] -> {:error, "Failed to find a DM channel for this user: #{user_id}"}
    end
  end

  def private_channel(channel_id) do
    case :ets.lookup(:priv_channels, channel_id) do
      [{_, channel}] -> {:ok, DMChannel.from_map(channel)}
      [] -> {:error, "Failed to find a DM channel entry for #{channel_id}."}
    end
  end

  @doc """
  Gets the user struct for this client from the cache.

  ## Examples
  ```elixir
  Cogs.def hello do
    Cogs.say "hello, my name is \#{Cache.user().name}"
  end
  ```
  """
  @spec user :: User.t()
  def user do
    GenServer.call(Alchemy.Cache.User, :get)
    |> to_struct(User)
  end

  @doc """
  Requests the loading of offline guild members for a guild.

  Guilds should automatically get 250 offline members after the
  `:ready` event, however, you can use this method to request a fuller
  list if needed.

  The `username` is used to only select members whose username starts
  with a certain string; `""` won't do any filtering. The `limit`
  specifies the amount of members to get; `0` for unlimited.

  There's a ratelimit of ~100 requests per shard per minute on this
  function, so be wary of the fact that this might block a process.
  """
  def load_guild_members(guild_id, username \\ "", limit \\ 0) do
    Gateway.request_guild_members(guild_id, username, limit)
  end
end
