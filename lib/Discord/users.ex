defmodule Alchemy.Discord.Users do
  require Poison
  alias Alchemy.Discord.Api
  alias Alchemy.Discord.RateLimits
  @moduledoc false
  defmodule User do
    @moduledoc """
    Represents a discord user. The default values exist to cover missing fields.

    > **id**

      represents a unique client id
    > **username**

      represents a client's current username
    > **discriminator**

      4 digit tag to differenciate usernames
    > **avatar**

      A string representing their avatar hash
    > **bot**

      Whether or not the user is a bot - *default: `false`*

    A bot usually doesn't have the authorization necessary to access these 2, so
    they're usually missing.
    > **verified**

      Whether the account is verified - *default: `:hidden`*
    > **avatar**

      The user's email - *default: `:hidden`*
    """
    @derive [Poison.Encoder]
    defstruct [:id,
               :username,
               :discriminator,
               :avatar,
               bot: false,
               verified: :hidden,
               email: :hidden
               ]
  end

  @root_url "https://discordapp.com/api/users/"
  # Returns a User struct, passing "@me" gets info for the current Client instead
  # Token is the first arg so that it can be prepended generically
  def get_user(token, client_id) do
    response = Api.get(@root_url <> client_id, token)
    rate_info = RateLimits.rate_info(response)
    user = Poison.decode!(response.body, as: %User{})
    {:ok, user, rate_info}
  end

  def modify_user(token, {:user_name, user_name}, {:avatar, url}) do
    {:ok, avatar} = Api.fetch_avatar(url)
    request = ~s/{"username": "#{user_name}", "avatar": "#{avatar}"}/
    response = Api.patch(@root_url <> "@me", request, token)
    rate_info = RateLimits.rate_info(response)
    user = Poison.decode!(response.body, as: %User{})
    {:ok, user, rate_info}
  end

  def modify_user(token, {:user_name, user_name}) do
    request = ~s/{"username": "#{user_name}"}/
    response = Api.patch(@root_url <> "@me", request, token)
    rate_info = RateLimits.rate_info(response)
    user = Poison.decode!(response.body, as: %User{})
    {:ok, user, rate_info}
  end

  def modify_user(token, {:avatar, url}) do
    {:ok, avatar} = Api.fetch_avatar(url)
    request = ~s/{"avatar": "#{avatar}"}/
    response = Api.patch(@root_url <> "@me", request, token)
    rate_info = RateLimits.rate_info(response)
    user = Poison.decode!(response.body, as: %User{})
    {:ok, user, rate_info}
  end
  defmodule UserGuild do
    @moduledoc """
    A
    """
    @derive [Poison.Encoder]
    defstruct [:id,
               :name,
               :icon,
               :owner,
               :permissions
               ]
  end

  # Returns a list of %UserGuilds the current user is a member of.
  def get_current_guilds(token) do
    response = Api.get(@root_url <> "@me" <> "/guilds", token)
    rate_info = RateLimits.rate_info(response)
    guilds = Poison.decode!(response.body, as: [%UserGuild{}])
    {:ok, guilds, rate_info}
  end
end
