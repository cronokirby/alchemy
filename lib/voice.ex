defmodule Alchemy.Voice do
  @moduledoc """
  Serves as the main interface for interacting with discord's voice API.
  """
  alias Alchemy.Voice.Supervisor, as: VoiceSuper
  alias Alchemy.Discord.Gateway.RateLimiter

  @doc """
  joins a voice channel
  """
  def join(guild, channel, timeout \\ 6000) do
    VoiceSuper.start_client(guild, channel, timeout)
  end


  def leave(guild) do
    case Registry.lookup(Registry.Voice, {guild, :gateway}) do
      [] ->
        {:error, "You're not joined to voice in this guild."}
      [{pid, _}|_] ->
        Supervisor.terminate_child(VoiceSuper.Gateway, pid)
        RateLimiter.change_voice_state(guild, nil)
    end
  end
end
