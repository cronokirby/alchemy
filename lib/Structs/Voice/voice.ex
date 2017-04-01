defmodule Alchemy.Voice do
  @moduledoc """
  Contains the types and functions related to voice communication with discord.
  """
  alias Alchemy.{VoiceState, VoiceRegion}

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

end
