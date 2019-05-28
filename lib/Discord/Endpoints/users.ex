defmodule Alchemy.Discord.Users do
  @moduledoc false
  alias Alchemy.Discord.Api
  alias Alchemy.{Channel.DMChannel, User, UserGuild}

  @root "https://discordapp.com/api/v6/users/"

  # Returns a User struct, passing "@me" gets info for the current Client instead
  # Token is the first arg so that it can be prepended generically
  def get_user(token, client_id) do
    Api.get(@root <> client_id, token, %User{})
  end

  # Modify the client's user account settings.
  def modify_user(token, options) do
    {_, options} =
      options
      |> Keyword.get_and_update(:avatar, fn
        nil -> :pop
        some -> {some, Api.fetch_avatar(some)}
      end)

    Api.patch(@root <> "@me", token, Api.encode(options), %User{})
  end

  # Returns a list of %UserGuilds the current user is a member of.
  def get_current_guilds(token) do
    (@root <> "@me/guilds")
    |> Api.get(token, [%UserGuild{}])
  end

  # Removes a client from a guild
  def leave_guild(token, guild_id) do
    (@root <> "@me/guilds/" <> guild_id)
    |> Api.delete(token)
  end

  # Gets a list of DMChannel objects for a user
  def get_DMs(token) do
    (@root <> "@me/channels")
    |> Api.get(token, Api.parse_map(DMChannel))
  end

  def create_DM(token, user_id) do
    json = ~s/{"recipient_id": #{user_id}}/

    (@root <> "@me/channels")
    |> Api.post(token, json, DMChannel)
  end
end
