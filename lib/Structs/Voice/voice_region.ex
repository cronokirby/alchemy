defmodule Alchemy.VoiceRegion do
  @moduledoc """
  """
  @type t :: %__MODULE__{
    id: String.t,
    name: String.t,
    sample_hostname: String.t,
    sample_port: Integer,
    vip: Boolean,
    optimal: Boolean,
    deprecated: Boolean,
    custom: Boolean
  }
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
