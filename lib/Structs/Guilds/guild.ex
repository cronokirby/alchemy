defmodule Alchemy.Guild do
  alias Alchemy.Role
  alias Alchemy.Emoji
  alias Alchemy.Channel
  alias ALchemy.GuildMember
  alias Alchemy.VoiceState
  @moduledoc """
  """
  @type t :: %__MODULE__{
    id: String.t,
    name: String.t,
    icon: String.t,
    splash: String.t,
    owner: String.t,
    region: String.t,
    afk_channel_id: String.t,
    afk_timeout: Integer,
    embed_enabled: Boolean,
    verification_level: Integer,
    default_message_notifications: Integer,
    roles: [Role.t],
    emojis: [Emoji.t],
    features: [String.t],
    mfa_level: Integer,
    joined_at: String.t,
    large: Boolean,
    unavailable: Boolean,
    member_count: Integer,
    voice_states: [VoiceState.t],
    members: [GuildMember.t],
    channels: [Channel.t],
    presences: String.t
  }
  @derive Poison.Encoder
  defstruct [:id,
             :name,
             :icon,
             :splash,
             :owner,
             :region,
             :afk_channel_id,
             :afk_timeout,
             :embed_enabled,
             :verification_level,
             :default_message_notifications,
             :roles,
             :emojis,
             :features,
             :mfa_level,
             :joined_at,
             :large,
             :unavailable,
             :member_count,
             :voice_states,
             :members,
             :channels,
             :presences
             ]
end
