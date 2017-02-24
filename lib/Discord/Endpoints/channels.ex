defmodule Alchemy.Discord.Channels do
  alias Poison.Parser
  alias Alchemy.Discord.Api
  alias Alchemy.{Channel, Channel.Invite, DMChannel, Message, User, Reaction.Emoji}
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
     @root <> channel_id <> "/messages" <> Api.query(options)
     |> Api.get(token, parser)
  end


  def channel_message(token, channel_id, message_id) do
    @root <> channel_id <> "/messages" <> message_id
    |> Api.get(token, Message)
  end


  def create_message(token, channel_id, options) do
    @root <> channel_id <> "/messages"
    |> Api.post(token, Api.encode(options), Message)
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


  defp modify_reaction(token, channel_id, message_id,
                       %Emoji{id: nil, name: name}, stub, request) do
      @root <> channel_id <> "/messages/" <> message_id
            <> "/reactions/" <> name <> stub
      |> URI.encode
      |> request.(token)
  end
  defp modify_reaction(token, channel_id, message_id,
                       %Emoji{id: id, name: name}, stub, request) do
      @root <> channel_id <> "/messages/" <> message_id
            <> "/reactions/" <> ":#{name}:#{id}" <> stub
      |> URI.encode
      |> request.(token)
  end


  def create_reaction(token, channel_id, message_id, emoji) do
    modify_reaction(token, channel_id, message_id, emoji, "/@me", &Api.put/2)
  end


  def delete_own_reaction(token, channel_id, message_id, emoji) do
    modify_reaction(token, channel_id, message_id, emoji, "/@me", &Api.delete/2)
  end


  def delete_reaction(token, channel_id, message_id, emoji, user_id) do
    stub = "/#{user_id}"
    modify_reaction(token, channel_id, message_id, emoji, stub, &Api.delete/2)
  end


  def get_reactions(token, channel_id, message_id, %Emoji{id: nil, name: name}) do
    @root <> channel_id <> "/messages/" <> message_id <> "/reactions/"
          <> name
    |> URI.encode
    |> Api.get(token, [%User{}])
  end
  def get_reactions(token, channel_id, message_id, %Emoji{id: id, name: name}) do
    @root <> channel_id <> "/messages/" <> message_id <> "/reactions/"
          <> ":#{name}:#{id}"
    |> URI.encode
    |> Api.get(token, [%User{}])
  end


  def delete_reactions(token, channel_id, message_id) do
    @root <> channel_id <> "/messages/" <> message_id <> "/reactions"
    |> Api.delete(token)
  end


  def get_channel_invites(token, channel_id) do
    parser = fn json ->
      json
      |> Parser.parse!
      |> Enum.map(&Invite.from_map/1)
    end
    @root <> channel_id <> "/invites"
    |>  Api.get(token, parser)
  end


  def create_channel_invite(token, channel_id, options) do
    @root <> channel_id <> "/invites"
    |> Api.post(Api.encode(options), token, Invite)
  end
end
