defmodule Alchemy.Channel.Invite.InviteChannel do
  @moduledoc """
  Represents the channel an invite is for

  - `id`

    The id of the channel
  - `name`

    The name of the channel
  - `type`

    the type of the channel, either "text" or "voice"
  """
  @type snowflake :: String.t

  @type t :: %__MODULE__{
    id: snowflake,
    name: String.t,
    type: String.t
  }
  @derive Poison.Encoder
  defstruct [:id,
             :name,
             :type
            ]
end
