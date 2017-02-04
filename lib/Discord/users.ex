defmodule Alchemy.Discord.Users do
  require Poison
  alias Alchemy.Discord.Api
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
    * `verified` - Whether the account is verified - *default: `:hidden`*
    * `email` The user's email - *default: `:hidden`*
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
  # Returns a User struct, passing :me gets info for the current Client instead
  def get_user(:me, token) do
   get_user("@me", token)
  end
  def get_user(client_id, token) do
    json = Api.get(@root_url <> client_id, token).body
    user = Poison.decode!(json, as: %User{})
    {:ok, user}
  end
end
