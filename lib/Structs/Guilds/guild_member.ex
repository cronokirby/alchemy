defmodule Alchemy.GuildMember do
  alias Alchemy.User
  alias Alchemy.Role
  @moduledoc """
  """
  @type t :: %__MODULE__{
    user: User.t,
    nick: String.t | nil,
    roles: [Role.t],
    joined_at: String.t,
    deaf: Boolean,
    mute: Boolean
  }
  defstruct [:user,
             :nick,
             :roles,
             :joined_at,
             :deaf,
             :mute]
end
