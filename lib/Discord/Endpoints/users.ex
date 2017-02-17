defmodule Alchemy.Discord.Users do
  alias Alchemy.Discord.Api
  alias Alchemy.{User, UserGuild}
  @moduledoc false

  @root "https://discordapp.com/api/users/"

  # Returns a User struct, passing "@me" gets info for the current Client instead
  # Token is the first arg so that it can be prepended generically
  def get_user(token, client_id) do
    Api.get(@root <> client_id, token, %User{})
  end


  # Modify the client's user account settings. Returns {:ok, %User{}, rate_info}
  def modify_user(token, options) do
    Api.patch(@root <> "@me", Api.encode(options), token, %User{})
  end


  # Returns a list of %UserGuilds the current user is a member of.
  def get_current_guilds(token) do
    url = @root <> "@me" <> "/guilds"
    Api.get(url, token, [%UserGuild{}])
  end


  # Removes a client from a guild
  def leave_guild(token, guild_id) do
    url = @root <> "@me/guilds/#{guild_id}"
    Api.delete(url, token)
  end
end
