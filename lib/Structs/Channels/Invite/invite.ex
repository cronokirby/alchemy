defmodule Alchemy.Channel.Invite do
  @moduledoc false
  alias Alchemy.Channel.Invite.{InviteChannel, InviteGuild}
  import Alchemy.Structs

  defstruct [
    :code,
    :guild,
    :channel,
    :inviter,
    :uses,
    :max_uses,
    :max_age,
    :temporary,
    :created_at,
    :revoked
  ]

  def from_map(map) do
    map
    |> field("guild", InviteGuild)
    |> field("channel", InviteChannel)
    |> to_struct(__MODULE__)
  end
end
