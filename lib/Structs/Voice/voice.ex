defmodule Alchemy.Voice do
  @moduledoc """
  Contains the types and functions related to voice communication with discord.

  To use the functions in this module, make sure to configure the paths
  to `ffmpeg`, as well as `youtube-dl`, like so:
  ```elixir
  config :alchemy,
    ffmpeg_path: "path/to/ffmpeg"
    youtube_dl_path: "path/to/youtube-dl"
  ```
  If these are not configured, the necessary supervisors for maintaining
  voice connections won't be started, and you'll run into errors when trying
  to use the functions in this module.
  """
  alias Alchemy.{VoiceState, VoiceRegion}
  alias Alchemy.Voice.Supervisor, as: VoiceSuper
  alias Alchemy.Discord.Gateway.RateLimiter

  @type snowflake :: String.t()

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
          name: String.t(),
          sample_hostname: String.t(),
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
          session_id: String.t(),
          deaf: Boolean,
          mute: Boolean,
          self_deaf: Boolean,
          self_mute: Boolean,
          suppress: Boolean
        }
  @typedoc """
  Represents the audio options that can be passed to different play methods.  

  ## Options
  - `vol` audio volume, in `%`. Can go above 100 to multiply, e.g. `150`.
  """
  @type audio_options :: [{:vol, integer}]

  @doc """
  Joins a voice channel in a guild.

  Only one voice connection per guild is possible with the api.
  If you're already connected to the guild, this will not restart the
  voice connections, but instead just move you to the channel.

  This function also checks if you're already connected to this channel,
  and does nothing if that is the case.

  The timeout will be spread across 2 different message receptions,
  i.e. a timeout of `6000` will only wait 3s at every reception.
  """
  @spec join(snowflake, snowflake, integer) :: :ok | {:error, String.t()}
  def join(guild, channel, timeout \\ 6000) do
    case Registry.lookup(Registry.Voice, {guild, :gateway}) do
      [{_, ^channel} | _] -> :ok
      _ -> VoiceSuper.start_client(guild, channel, timeout)
    end
  end

  @doc """
  Disconnects from voice in a guild.

  Returns an error if the connection hadn’t been established.
  """
  @spec leave(snowflake) :: :ok | {:error, String.t()}
  def leave(guild) do
    case Registry.lookup(Registry.Voice, {guild, :gateway}) do
      [] ->
        {:error, "You're not joined to voice in this guild"}

      [{pid, _} | _] ->
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
  @spec play_file(snowflake, Path.t(), audio_options) :: :ok | {:error, String.t()}
  def play_file(guild, file_path, options \\ []) do
    with [{pid, _} | _] <- Registry.lookup(Registry.Voice, {guild, :controller}),
         true <- File.exists?(file_path) do
      GenServer.call(pid, {:play, file_path, :file, options})
    else
      [] -> {:error, "You're not joined to voice in this guild"}
      false -> {:error, "This file does not exist"}
    end
  end

  defp play_type(guild, type, data, options) do
    case Registry.lookup(Registry.Voice, {guild, :controller}) do
      [] -> {:error, "You're not joined to voice in this guild"}
      [{pid, _} | _] -> GenServer.call(pid, {:play, data, type, options})
    end
  end

  @doc """
  Starts playing audio from a url.

  For this to work, the url must be one of the
  [supported sites](https://rg3.github.io/youtube-dl/supportedsites.html).
  This function does not check the validity of this url, so if it's invalid,
  an error will get logged, and no audio will be played.
  """
  @spec play_url(snowflake, String.t(), audio_options) :: :ok | {:error, String.t()}
  def play_url(guild, url, options \\ []) do
    play_type(guild, :url, url, options)
  end

  @doc """
  Starts playing audio from an `iodata`, or a stream of `iodata`.

  Similar to `play_url/2` except it doesn't create a stream from
  `youtube-dl` for you.
  """
  @spec play_iodata(snowflake, iodata | Enumerable.t(), audio_options) ::
          :ok | {:error, String.t()}
  def play_iodata(guild, data, options \\ []) do
    play_type(guild, :iodata, data, options)
  end

  @doc """
  Stops playing audio on a guild's voice connection.

  Returns an error if the connection hadn't been established.
  """
  @spec stop_audio(snowflake) :: :ok | {:error, String.t()}
  def stop_audio(guild) do
    case Registry.lookup(Registry.Voice, {guild, :controller}) do
      [] -> {:error, "You're not joined to voice in this guild"}
      [{pid, _} | _] -> GenServer.call(pid, :stop_playing)
    end
  end

  @doc """
  Lets this process listen for the end of an audio track in a guild.

  This will subscribe this process up until the next time an audio track
  ends, to react to this, you'll want to handle the message in some way, e.g.
  ```elixir
  Voice.listen_for_end(guild)
  receive do
    {:audio_stopped, ^guild} -> IO.puts "audio has stopped"
  end
  ```
  This is mainly designed for use in genservers, or other places where you don't
  want to block. If you do want to block and wait immediately, try
  `wait_for_end/2` instead.

  ## Examples
  Use in a genserver:
  ```elixir
  def handle_info({:audio_stopped, guild}, state) do
    IO.puts "audio has stopped in \#{guild}"
    Voice.listen_for_end(guild)
    {:noreply, state}
  end
  ```
  """
  @spec listen_for_end(snowflake) :: :ok | {:error, String.t()}
  def listen_for_end(guild) do
    case Registry.lookup(Registry.Voice, {guild, :controller}) do
      [] -> {:error, "You're not joined to voice in this guild"}
      [{pid, _} | _] -> GenServer.call(pid, :add_listener)
    end
  end

  @doc """
  Blocks the current process until audio has stopped playing in a guild.

  This is a combination of `listen_for_end/1` and a receive block,
  however this will return an error if the provided timeout is exceeded.
  This is useful for implementing automatic track listing, e.g.
  ```elixir
  def playlist(guild, tracks) do
    Enum.map(tracks, fn track ->
      Voice.play_file(guild, track)
      Voice.wait_for_end(guild)
    end)
  end
  ```
  """
  @spec wait_for_end(snowflake, integer | :infinity) :: :ok | {:error, String.t()}
  def wait_for_end(guild, timeout \\ :infinity) do
    listen_for_end(guild)

    receive do
      {:audio_stopped, ^guild} -> :ok
    after
      timeout -> {:error, "Timed out waiting for audio"}
    end
  end

  @doc """
  Returns which channel the client is connected to in a guild.

  Returns `nil` if there is no connection.
  """
  @spec which_channel(snowflake) :: snowflake | nil
  def which_channel(guild) do
    case Registry.lookup(Registry.Voice, {guild, :gateway}) do
      [{_, channel} | _] -> channel
      _ -> nil
    end
  end
end
