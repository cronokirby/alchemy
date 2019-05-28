defmodule Alchemy.Channel.Invite.InviteChannel do
  @moduledoc false

  @derive Poison.Encoder
  defstruct [:id, :name, :type]
end
