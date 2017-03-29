defmodule Alchemy.Webhook do
  @moduledoc """
  """
  alias Alchemy.Discord.Webhooks
  alias Alchemy.{Embed, User}
  import Alchemy.Discord.RateManager, only: [send_req: 2]

  @type snowflake :: String.t


  @type t :: %__MODULE__{
    id: snowflake,
    guild_id: snowflake | nil,
    channel_id: snowflake,
    user: User.t | nil,
    name: String.t | nil,
    avatar: String.t | nil,
    token: String.t
  }


  defstruct [:id,
             :guild_id,
             :channel_id,
             :user,
             :name,
             :avatar,
             :token]


  @doc """
  Creates a new webhook in a channel.

  The name parameter is mandatory, and specifies the name of the webhook.
  of course.
  ## Options
  - `avatar`
    A link to a 128x128 image to act as the avatar of the webhook.
  ## Examples
  ```elixir
  {:ok, hook} = Task.await Webhook.create("66666", "The Devil")
  ```
  """
  @spec create(snowflake, String.t, [avatar: String.t]) :: {:ok, __MODULE__.t}
                                                         | {:error, term}
  def create(channel_id, name, options \\ []) do
    {Webhooks, :create_webhook, [channel_id, name, options]}
    |> send_req("/channels/webhooks")
  end
  @doc """
  Returns a list of all webhooks in a channel.
  ## Example
  ```elixir
  {:ok, [%Webhook{} | _]} = Task.await Webhook.in_channel("6666")
  ```
  """
  @spec in_channel(snowflake) :: {:ok, [__MODULE__.t]} | {:error, term}
  def in_channel(channel_id) do
    {Webhooks, :channel_webhooks, [channel_id]}
    |> send_req("/channels/webhooks")
  end
  @doc """
  Returns a list of all webhooks in a guild.
  ## Example
  ```elixir
  {:ok, [%Webhook{} | _]} = Task.await Webhook.in_guild("99999")
  ```
  """
  @spec in_guild(atom) :: {:ok, [__MODULE__.t]} | {:error, term}
  def in_guild(guild_id) do
    {Webhooks, :guild_webhooks, [guild_id]}
    |> send_req("/guilds/webhooks")
  end
  @doc """
  Modifies the settings of a webhook.

  Note that the user field of the webhook will be missing.

  ## Options
  - `name`
    The name of the webhook.
  - `avatar`
    A link to a 128x128 icon image.

  ## Examples
  ```elixir
  {:ok, hook} = Task.await Webhook.create("6666", "Captian Hook")
  # Let's fix that typo:
  Webhook.edit(hook, name: "Captain Hook")
  ```
  """
  @spec edit(__MODULE__.t,
             [name: String.t, avatar: String.t]) :: {:ok, __MODULE__.t}
                                                  | {:error, term}
  def edit(%__MODULE__{id: id, token: token}, options) do
    {Webhooks, :modify_webhook, [id, token, options]}
    |> send_req("/webhooks")
  end
  @doc """
  Deletes a webhook.

  All you need for this is the webhook itself.
  ## Examples
  ```elixir
  {:ok, wh} = Task.await Webhook.create("666", "Captain Hook")
  Webhook.delete(wh)
  ```
  """
  @spec delete(__MODULE__.t) :: {:ok, __MODULE__.t} | {:error, term}
  def delete(%__MODULE__{id: id, token: token}) do
    {Webhooks, :delete_webhook, [id, token]}
    |> send_req("/webhooks")
  end


  def send(%__MODULE__{id: id, token: token}, {type, content}, options \\ []) do
    {type, content} = case {type, content} do
      {:embed, em} ->
        {:embeds, [Embed.build(em)]}
      {t, c} ->
        {t, c}
    end
    options = Keyword.put(options, type, content)
    {Webhooks, :execute_webhook, [id, token, options]}
    |> send_req("/webhooks")
  end
end
