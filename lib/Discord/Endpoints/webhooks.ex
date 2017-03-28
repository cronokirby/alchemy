defmodule Alchemy.Discord.Webhooks do
  @moduledoc false
  alias Alchemy.Discord.Api
  alias Alchemy.Webhook

  @root "https://discordapp.com/api/v6/"


  def create_webhook(token, channel_id, name, options) do
    options = case options do
      [] ->
        [name: name]
      [avatar: url] ->
        [name: name, avatar: Api.image_data(url)]
    end
    |> Api.encode
    @root <> "channels/" <> channel_id <> "/webhooks"
    |> Api.post(token, options, %Webhook{})
  end
end
