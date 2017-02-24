defmodule Alchemy.Discord.Channels do
  alias Poison.Parser
  alias Alchemy.Discord.Api
  alias Alchemy.{Channel, DMChannel, Message, Reaction.Emoji}
  import Alchemy.Structs.Utility
  @moduledoc false

  @root "https://discordapp.com/api/channels/"


  def parse_channel(json) do
    parsed = Parser.parse!(json)
    if parsed["is_private"] do
      to_struct(parsed, DMChannel)
    else
      Channel.from_map(parsed)
    end
  end


  def get_channel(token, channel_id) do
    Api.get(@root <> channel_id, token, &parse_channel/1)
  end


  def modify_channel(token, channel_id, options) do
    Api.patch(@root <> channel_id, token, Api.encode(options), Channel)
  end


  def delete_channel(token, channel_id) do
    Api.delete(@root <> channel_id, token, &parse_channel/1)
  end


  def channel_messages(token, channel_id, options) do
     parser = fn json ->
       json
       |> Parser.parse!
       |> Enum.map(&Message.from_map/1)
     end
     url = @root <> channel_id <> "/messages"
     Api.get(url <> Api.query(options), token, parser)
  end


  def channel_message(token, channel_id, message_id) do
    url = @root <> channel_id <> "/messages" <> message_id
    Api.get(url, token, Message)
  end


  def create_message(token, channel_id, options) do
    url = @root <> channel_id <> "/messages"
    Api.post(url, token, Api.encode(options), Message)
  end


  def edit_message(token, channel_id, message_id, content) do
    url = @root <> channel_id <> "/messages/" <> message_id
    json = ~s/{"content": "#{content}"}/
    Api.patch(url, token, json, Message)
  end


  def delete_message(token, channel_id, message_id) do
    url = @root <> channel_id <> "/messages/" <> message_id
    Api.delete(url, token)
  end


  def delete_messages(token, channel_id, messages) do
    json = Poison.encode!(%{messages: messages})
    url = @root <> channel_id <> "/messages/bulk-delete"
    Api.post(url, token, json)
  end


  def create_reaction(token, channel_id, message_id, %Emoji{id: nil, name: name}) do
    IO.inspect name
    url = (@root <> channel_id <> "/messages/" <> message_id
           <> "/reactions/" <> name <> "/@me")
        |> URI.encode
    Api.put(url, token)
  end
end
