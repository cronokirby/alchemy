defmodule Alchemy.User do
  @moduledoc """
  This module contains functions and types related to discord users.
  """
  alias Alchemy.UserGuild
  use Alchemy.Discord.Types

  @typedoc """
  Represents a discord User. The default values exist to cover missing fields.

  - `id`

    represents a unique user id
  - `username`

    represents a user's current username
  - `discriminator`

    4 digit tag to differenciate usernames
  - `avatar`

    A string representing their avatar hash. Use `avatar_url` to
    get the corresponding url from a `User` object
  - `bot`

    Whether or not the user is a bot - *default: `false`*

  A bot usually doesn't have the authorization necessary to access these 2, so
  they're usually missing.
  - `verified`

    Whether the account is verified - *default: `:hidden`*
  - `email`

    The user's email - *default: `:hidden`*
  """
  @type t :: %__MODULE__{
          id: String.t(),
          username: String.t(),
          discriminator: String.t(),
          avatar: String.t(),
          bot: Boolean,
          verified: :hidden | Boolean,
          email: :hidden | String.t()
        }
  @derive [Poison.Encoder]
  defstruct [
    :id,
    :username,
    :discriminator,
    :avatar,
    bot: false,
    verified: :hidden,
    email: :hidden
  ]

  @typedoc """
  A shortened version of a Guild struct, through the view of a User.

  - `id`

    Represents the guild's id.
  - `name`

    Represents the guild's name.
  - `icon`

    A string representing the guild's icon hash.
  - `owner`

    Whether the user linked to the guild owns it.
  - `permissions`

    Bitwise of the user's enabled/disabled permissions.
  """
  @type user_guild :: %UserGuild{
          id: snowflake,
          name: String.t(),
          icon: String.t(),
          owner: Boolean,
          permissions: Integer
        }
  defimpl String.Chars, for: __MODULE__ do
    def to_string(user), do: user.username <> "#" <> user.discriminator
  end

  defmacrop is_valid_img(type, size) do
    quote do
      unquote(type) in ["png", "webp", "jpg", "gif"] and
        unquote(size) in [128, 256, 512, 1024, 2048]
    end
  end

  @doc """
  Used to get the url for a user's avatar

  `type` must be one of `"png"`, `"webp"`, `"jpg"`, `"gif"`

  `size` must be one of `128`, `256`, `512`, `1024`, `2048`

  ## Examples
  ```elixir
  > User.avatar_url(user)
  https://cdn.discordapp.com/avatars/...
  ```
  """
  @spec avatar_url(__MODULE__.t(), String.t(), Integer) :: url
  def avatar_url(user) do
    avatar_url(user, "jpg", 128)
  end

  def avatar_url(user, type, size) when is_valid_img(type, size) do
    base = "https://cdn.discordapp.com/avatars/#{user.id}/#{user.avatar}."
    base <> "#{type}?size=#{size}"
  end

  def avatar_url(_user, _type, _size) do
    raise ArgumentError, message: "invalid type and/or size"
  end

  @doc """
  Returns a string that mentions a user when used in a message
  """
  def mention(user) do
    "<@#{user.id}>"
  end
end
