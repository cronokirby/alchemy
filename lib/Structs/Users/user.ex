defmodule Alchemy.User do
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
  > **email**

    The user's email - *default: `:hidden`*
  """
  @type t :: %__MODULE__{
    id: String.t,
    username: String.t,
    discriminator: String.t,
    avatar: String.t,
    bot: Boolean,
    verified: :hidden | Boolean,
    email: :hidden | String.t
  }
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
