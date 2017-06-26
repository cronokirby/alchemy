defmodule Alchemy.Voice.Controller do
  use GenServer
  require Logger
  alias Alchemy.Voice.Supervisor.VoiceRegistry
  alias Porcelain.Process, as: Proc

  defmodule State do
    defstruct [:udp, :key, :ssrc, :ip, :port, :guild_id, :player, :ws]
  end

  def start_link(udp, key, ssrc, ip, port, guild_id, me) do
    state = %State{udp: udp, key: key, ssrc: ssrc,
                   ip: ip, port: port, guild_id: guild_id, ws: me}
    GenServer.start_link(__MODULE__, state,
                         name: VoiceRegistry.via({guild_id, :controller}))
  end

  def init(state) do
    Logger.debug "Voice Controller for #{state.guild_id} started"
    {:ok, state}
  end

  def handle_cast({:send_audio, data}, state) do
    :gen_udp.send(state.udp, state.ip, state.port, data)
    {:noreply, state}
  end

  def handle_call({:play, path, type}, _, state) do
    self = self()
    player = Task.async(fn ->
      run_player(path, type, self,
        %{ssrc: state.ssrc, key: state.key, ws: state.ws})
    end)
    {:reply, :ok, %{state | player: player}}
  end

  def handle_call(:stop_playing, _, state) do
    Task.shutdown(state.player)
    {:reply, :ok, state}
  end

  # ignore down messages from the task
  def handle_info(_, state) do
    {:noreply, state}
  end

  ## Audio stuff ##

  @ffmpeg "../porcytest/ffmpeg"

  defp header(sequence, time, ssrc) do
    <<0x80, 0x78, sequence::size(16), time::size(32), ssrc::size(32)>>
  end

  defp mk_stream(file_path) do
    %Proc{out: audio_stream} =
      Porcelain.spawn(@ffmpeg,
        ["-hide_banner", "-loglevel", "quiet", "-i","#{file_path}",
         "-f", "data", "-map", "0:a", "-ar", "48k", "-ac",
         "2", "-acodec", "libopus", "-b:a", "128k", "pipe:1"], [out: :stream])
    audio_stream
  end

  @youtube_dl "../porcytest/youtube-dl"

  defp youtube_stream(url) do
      %Proc{out: youtube} = Porcelain.spawn(@youtube_dl,
        ["-q", "-f", "bestaudio", "-o", "-", url], [out: :stream])
      opts = [in: youtube, out: :stream]
      %Proc{out: audio_stream} =
        Porcelain.spawn(@ffmpeg,
          ["-hide_banner", "-loglevel", "quiet", "-i","pipe:0",
           "-f", "data", "-map", "0:a", "-ar", "48k", "-ac",
           "2", "-acodec", "libopus", "-b:a", "128k", "pipe:1"], opts)
      audio_stream
  end

  defp run_player(path, type, parent, state) do
    send(state.ws, {:speaking, true})
    stream = case type do
      :file -> mk_stream(path)
      :yt -> youtube_stream(path)
    end
    {seq, time, _} =
      stream
      |> Enum.reduce({0, 0, nil}, fn packet, {seq, time, elapsed} ->
        packet = mk_audio(packet, seq, time, state)
        GenServer.cast(parent, {:send_audio, packet})
        # putting the elapsed time directly in the accumulator makes it incorrect
        elapsed = elapsed || :os.system_time(:milli_seconds)
        Process.sleep(do_sleep(elapsed))
        {seq + 1, time + 960, elapsed + 20}
      end)
    # We must send 5 frames of silence to end opus interpolation
    Enum.reduce(1..5, {seq, time}, fn _, {seq, time} ->
      GenServer.cast(parent, {:send_audio, <<0xF8, 0xFF, 0xFE>>})
      Process.sleep(20)
      {seq + 1, time + 960}
    end)
    send(state.ws, {:speaking, false})
  end

  defp mk_audio(packet, seq, time, state) do
    header = header(seq, time, state.ssrc)
    nonce = (header <> <<0::size(96)>>)
    header <> Kcl.secretbox(packet, nonce, state.key)
  end

  # this also takes care of adjusting for sleeps taking too long
  defp do_sleep(elapsed, delay \\ 20) do
    case elapsed - :os.system_time(:milli_seconds) + delay do
      x when x < 0 -> 0
      x -> x
    end
  end
end
