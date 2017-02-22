defmodule Alchemy.User do
  use Alchemy.Discord.Types
  @moduledoc """
  Represents a discord user. The default values exist to cover missing fields.

  - `id`

    represents a unique client id
  - `username`

    represents a client's current username
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
  @spec avatar_url(__MODULE__.t, String.t, Integer) :: url
  def avatar_url(user) do
     avatar_url(user, "jpg", 128)
  end
  def avatar_url(user, type, size) when is_valid_img(type, size) do
     base = "https://cdn.discordapp.com/avatars/#{user.id}/#{user.avatar}."
     base <> "#{type}?size=#{size}"
  end
  def avatar_url(user, type, size \\ 0) do
    raise ArgumentError, message: "invalid image type and/or size"
  end
end
