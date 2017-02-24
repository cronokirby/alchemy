defmodule Alchemy.Channel.Invite do
  alias Alchemy.User
  alias Alchemy.Channel.Invite.{InviteChannel, InviteGuild}
  import Alchemy.Structs.Utility
  @moduledoc """
  Represents an Invite object along with the metadata.

  - `code`

    The unique invite code
  - `guild`

    The guild this invite is for
  - `channel`

    The channel this invite is for
  - `inviter`

    The user who created the invite
  - `uses`

    The amount of time this invite has been used
  - `max_uses`

    The max number of times this invite can be used
  - `max_age`

    The duration (seconds) after which the invite will expire
  - `temporary`

    Whether this invite grants temporary membership
  - `created_at`

    When this invite was created
  - `revoked`

    Whether this invite was revoked
  """
  @type datetime :: String.t

  @type t :: %__MODULE__{
    code: String.t,
    guild: InviteGuild.t,
    channel: InviteChannel.t,
    inviter: User.t,
    uses: Integer,
    max_uses: Integer,
    max_age: Integer,
    temporary: Boolean,
    created_at: datetime,
    revoked: Boolean
  }
  defstruct [:code,
             :guild,
             :channel,
             :inviter,
             :uses,
             :max_uses,
             :max_age,
             :temporary,
             :created_at,
             :revoked]


  def from_map(map) do
    map
    |> field("guild", InviteGuild)
    |> field("channel", InviteChannel)
    |> to_struct(__MODULE__)
  end

end
