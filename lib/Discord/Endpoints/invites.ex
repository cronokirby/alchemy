defmodule Alchemy.Discord.Invites do
  @moduledoc false
  alias Alchemy.Discord.Api
  alias Alchemy.Channel.Invite
  @root "https://discordapp.com/api/v6/invites/"

  def get_invite(token, code) do
    (@root <> code)
    |> Api.get(token, Invite)
  end

  def delete_invite(token, code) do
    (@root <> code)
    |> Api.delete(token)
  end
end
