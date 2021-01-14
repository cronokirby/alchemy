defmodule Alchemy.Discord.Webhooks do
  @moduledoc false
  alias Alchemy.Discord.Api
  alias Alchemy.Webhook

  @root "https://discord.com/api/v6/"

  def create_webhook(token, channel_id, name, options) do
    options =
      case options do
        [] ->
          [name: name]

        [avatar: url] ->
          [name: name, avatar: Api.fetch_avatar(url)]
      end
      |> Api.encode()

    (@root <> "channels/" <> channel_id <> "/webhooks")
    |> Api.post(token, options, %Webhook{})
  end

  def channel_webhooks(token, channel_id) do
    (@root <> "channels/" <> channel_id <> "/webhooks")
    |> Api.get(token, [%Webhook{}])
  end

  def guild_webhooks(token, guild_id) do
    (@root <> "guilds/" <> guild_id <> "/webhooks")
    |> Api.get(token, [%Webhook{}])
  end

  def modify_webhook(token, id, wh_token, options) do
    options =
      case options do
        [{:avatar, url} | rest] ->
          [{:avatar, Api.fetch_avatar(url)} | rest]

        other ->
          other
      end
      |> Api.encode()

    (@root <> "/webhooks/" <> id <> "/" <> wh_token)
    |> Api.patch(token, options, %Webhook{})
  end

  def delete_webhook(token, id, wh_token) do
    (@root <> "/webhooks/" <> id <> "/" <> wh_token)
    |> Api.delete(token)
  end

  def execute_webhook(token, id, wh_token, options) do
    (@root <> "/webhooks/" <> id <> "/" <> wh_token)
    |> Api.post(token, Api.encode(options))
  end
end
