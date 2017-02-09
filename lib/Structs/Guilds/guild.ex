defmodule Alchemy.Guild do
  alias Alchemy.Role
  alias Alchemy.Emoji
  alias Alchemy.Channel
  alias ALchemy.GuildMember
  alias Alchemy.VoiceState
  alias Alchemy.Presence
  import Alchemy.Structs.Utility
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
    presences: [Presence.t]
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

  def from_map(map) do
    map
    |> Map.get_and_update("roles", &(map_struct &1, Role))
    |> Map.get_and_update("emojis", &(map_struct &1, Emoji))
    |> Map.get_and_update("voice_states", &(map_struct &1, VoiceState))
    |> Map.get_and_update("members", &(map_struct &1, GuildMember))
    |> Map.get_and_update("channels", &(map_struct &1, Channel))
    |> Map.get_and_update("presences", &(map_struct &1, Presence))
    |> to_struct(Guild)
  end
end
