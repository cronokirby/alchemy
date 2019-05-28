defmodule Alchemy.Channel.Invite.InviteGuild do
  @moduledoc false

  @derive Poison.Encoder
  defstruct [:id, :name, :splash, :icon]
end
