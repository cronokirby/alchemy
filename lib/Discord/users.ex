defmodule Alchemy.Discord.Users do
  require Poison
  alias Alchemy.User
  alias Alchemy.UserGuild
  alias Alchemy.Discord.Api
  alias Alchemy.Discord.RateLimits
  @moduledoc false
  @root_url "https://discordapp.com/api/users/"

  # Returns a User struct, passing "@me" gets info for the current Client instead
  # Token is the first arg so that it can be prepended generically
  def get_user(token, client_id) do
    Api.handle_response(:get, [@root_url <> client_id, token], %User{})
  end


  # Modify the client's user account settings. Returns {:ok, %User{}, rate_info}
  def modify_user(token, {:user_name, user_name}) do
    request = ~s/{"username": "#{user_name}"}/
    Api.handle_response(:patch, [@root_url <> "@me", request, token], %User{})
  end
  def modify_user(token, {:avatar, url}) do
    {:ok, avatar} = Api.fetch_avatar(url)
    request = ~s/{"avatar": "#{avatar}"}/
    Api.handle_response(:patch, [@root_url <> "@me", request, token], %User{})
  end
  def modify_user(token, {:user_name, user_name}, {:avatar, url}) do
    {:ok, avatar} = Api.fetch_avatar(url)
    request = ~s/{"username": "#{user_name}", "avatar": "#{avatar}"}/
    Api.handle_response(:patch, [@root_url <> "@me", request, token], %User{})
  end


  # Returns a list of %UserGuilds the current user is a member of.
  def get_current_guilds(token) do
    url = @root_url <> "@me" <> "/guilds"
    Api.handle_response(:get, [url, token], [%UserGuild{}])
  end


  # Removes a client from a guild
  def leave_guild(token, guild_id) do
    url = @root_url <> "@me/guilds/#{guild_id}"
    Api.handle_response(:delete, [url, token])
  end
end
