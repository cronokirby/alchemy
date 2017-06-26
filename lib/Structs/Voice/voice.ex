defmodule Alchemy.Voice do
  @moduledoc """
  Contains the types and functions related to voice communication with discord.
  """
  alias Alchemy.{VoiceState, VoiceRegion}
  alias Alchemy.Voice.Supervisor, as: VoiceSuper
  alias Alchemy.Discord.Gateway.RateLimiter

  @type snowflake :: String.t

  @typedoc """
  Represents a voice region.

  - `id`
    Represent the unique ID for this region.
  - `name`
    The name of this region.
  - `sample_hostname`
    An example hostname for the region.
  - `sample_port`
    An example port for the region.
  - `vip`
    True if this is a vip-only server.
  - `optimal`
    True for a single server that is closest to the client.
  - `deprecated`
    Whether this is a deprecated voice region.
  - `custom`
    Whether this is a custom voice region.
  """
  @type region :: %VoiceRegion{
    id: snowflake,
    name: String.t,
    sample_hostname: String.t,
    sample_port: Integer,
    vip: Boolean,
    optimal: Boolean,
    deprecated: Boolean,
    custom: Boolean
  }
  @typedoc """
  Represents the state of a user's voice connection.

  - `guild_id`
    The guild id this state is for.
  - `channel_id`
    The channel id this user is connected to.
  - `user_id`
    The id of the user this state belongs to.
  - `session_id`
    The session id for this voice state.
  - `deaf`
    Whether this user is deafened by the server.
  - `mute`
    Whether this user is muted by the server.
  - `self_deaf`
    Whether this user is locally deafened.
  - `self_mute`
    Whether this user is locally muted.
  - `suppress`
    Whether this user is muted by the current user.
  """
  @type state :: %VoiceState{
    guild_id: snowflake | nil,
    channel_id: snowflake,
    user_id: snowflake,
    session_id: String.t,
    deaf: Boolean,
    mute: Boolean,
    self_deaf: Boolean,
    self_mute: Boolean,
    suppress: Boolean
  }
  @doc """
  Joins a voice channel in a guild.

  Only one voice connection per guild is possible with the api.
  If you're already connected to the guild, this will not restart the
  voice connections, but instead just move you to the channel.

  The timeout will be spread across 2 different message receptions,
  i.e. a timeout of `6000` will only wait 3s at every reception.
  """
  @spec join(snowflake, snowflake, integer) :: :ok | {:error, String.t}
  def join(guild, channel, timeout \\ 6000) do
    VoiceSuper.start_client(guild, channel, timeout)
  end
  @doc """
  Disconnects from voice in a guild.

  Will return an error if already connected to the guild.
  """
  @spec leave(snowflake) :: :ok | {:error, String.t}
  def leave(guild) do
    case Registry.lookup(Registry.Voice, {guild, :gateway}) do
      [] ->
        {:error, "You're not joined to voice in this guild"}
      [{pid, _}|_] ->
        Supervisor.terminate_child(VoiceSuper.Gateway, pid)
        RateLimiter.change_voice_state(guild, nil)
    end
  end
  @doc """
  Starts playing a music file on a guild's voice connection.

  Returns an error if the client isn't connected to the guild,
  or if the file does not exist.

  ## Examples
  ```elixir
  Voice.join("666", "666")
  Voice.play_file("666", "cool_song.mp3")
  ```
  """
  @spec play_file(snowflake, Path.t) :: :ok
  def play_file(guild, file_path) do
    with [{pid, _}|_] <- Registry.lookup(Registry.Voice, {guild, :controller}),
         true <- File.exists?(file_path)
    do
      GenServer.call(pid, {:play, file_path, :file})
    else
      [] -> {:error, "You're not joined to voice in this guild"}
      false -> {:error, "This file does not exist"}
    end
  end
  @doc """
  Starts playing audio from a url.

  For this to work, the path to `youtube-dl` needs to be configured, and
  the url must be one of the [supported sites](https://rg3.github.io/youtube-dl/supportedsites.html).
  This function does not check the validity of this url, so if it's invalid,
  an error will get logged, and no audio will be played.
  """
  @spec play_youtube(snowflake, String.t) :: :ok
  def play_youtube(guild, url) do
    case Registry.lookup(Registry.Voice, {guild, :controller}) do
      [] -> {:error, "You're not joined to voice in this guild"}
      [{pid, _}|_] -> GenServer.call(pid, {:play, url, :yt})
    end
  end
  @doc """
  Stops playing audio on a guild's voice connection.

  Returns an error if the connection hadn't been established.
  """
  def stop_audio(guild) do
    case Registry.lookup(Registry.Voice, {guild, :controller}) do
      [] -> {:error, "You're not joined to voice in this guild"}
      [{pid, _}|_] -> GenServer.call(pid, :stop_playing)
    end
  end
end
