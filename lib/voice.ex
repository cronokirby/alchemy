defmodule Alchemy.Voice do
  @moduledoc """
  Serves as the main interface for interacting with discord's voice API.
  """
  alias Alchemy.Voice.Supervisor

  @doc """
  joins a voice channel
  """
  def join(guild, channel) do
    Supervisor.start_client(guild, channel)
  end

end
