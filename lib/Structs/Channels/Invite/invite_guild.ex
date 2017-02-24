defmodule Alchemy.Channel.Invite.InviteGuild do
  @moduledoc """
  Represents the guild an invite is for.

  - `id`

    The id of the guild
  - `name`

    The name of the guild
  - `splash`

    The hash of the guild splash (or nil)
  - `icon`

    The hash of the guild icon (or nil)
  """
  @type snowflake :: String.t
  @type hash :: String.t

  @type t :: %__MODULE__{
    id: snowflake,
    name: String.t,
    splash: hash,
    icon: hash
  }
  @derive Poison.Encoder
  defstruct [:id,
             :name,
             :splash,
             :icon]

end
