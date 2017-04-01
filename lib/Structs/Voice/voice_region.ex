defmodule Alchemy.VoiceRegion do
  @moduledoc false

  @derive Poison.Encoder
  defstruct [:id,
             :name,
             :sample_hostname,
             :sample_port,
             :vip,
             :optimal,
             :deprecated,
             :custom]
end
