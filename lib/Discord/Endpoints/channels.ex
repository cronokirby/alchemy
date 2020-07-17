defmodule Alchemy.Discord.Channels do
  @moduledoc false
  alias Poison.Parser
  alias Alchemy.Discord.Api
  alias Alchemy.{Channel, Channel.Invite, Channel.DMChannel, Message, User, Reaction.Emoji}

  @root "https://discord.com/api/v6/channels/"

  def parse_channel(json) do
    parsed = Parser.parse!(json, %{})

    if parsed["type"] == 1 do
      DMChannel.from_map(parsed)
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
    (@root <> channel_id <> "/messages" <> Api.query(options))
    |> Api.get(token, Api.parse_map(Message))
  end

  def channel_message(token, channel_id, message_id) do
    (@root <> channel_id <> "/messages/" <> message_id)
    |> Api.get(token, Message)
  end

  def create_message(token, channel_id, options) do
    url = @root <> channel_id <> "/messages"

    case Keyword.pop(options, :file) do
      {nil, options} ->
        Api.post(url, token, Api.encode(options), Message)

      # This branch requires a completely different request
      {file, options} ->
        options =
          case Keyword.pop(options, :embed) do
            {nil, options} ->
              options

            {embed, options} ->
              embed = %{"embed" => embed} |> Poison.encode!()
              [{:payload_json, embed} | options]
          end
          |> Enum.map(fn {k, v} -> {Atom.to_string(k), v} end)

        data = {:multipart, [{:file, file} | options]}

        headers = [
          {"Content-Type", "multipart/form-data"}
          | Api.auth_headers(token)
        ]

        HTTPoison.post(url, data, headers)
        |> Api.handle(Message)
    end
  end

  def edit_message(token, channel_id, message_id, options) do
    (@root <> channel_id <> "/messages/" <> message_id)
    |> Api.patch(token, Api.encode(options), Message)
  end

  def delete_message(token, channel_id, message_id) do
    (@root <> channel_id <> "/messages/" <> message_id)
    |> Api.delete(token)
  end

  def delete_messages(token, channel_id, messages) do
    json = Poison.encode!(%{messages: messages})

    (@root <> channel_id <> "/messages/bulk-delete")
    |> Api.post(token, json)
  end

  defp modify_reaction(token, channel_id, message_id, %Emoji{id: nil, name: name}, stub, request) do
    (@root <>
       channel_id <>
       "/messages/" <>
       message_id <>
       "/reactions/" <> name <> stub)
    |> URI.encode()
    |> request.(token)
  end

  defp modify_reaction(token, channel_id, message_id, %Emoji{id: id, name: name}, stub, request) do
    (@root <>
       channel_id <>
       "/messages/" <>
       message_id <>
       "/reactions/" <> ":#{name}:#{id}" <> stub)
    |> URI.encode()
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
    (@root <>
       channel_id <>
       "/messages/" <>
       message_id <>
       "/reactions/" <>
       name)
    |> URI.encode()
    |> Api.get(token, [%User{}])
  end

  def get_reactions(token, channel_id, message_id, %Emoji{id: id, name: name}) do
    (@root <>
       channel_id <>
       "/messages/" <>
       message_id <>
       "/reactions/" <>
       ":#{name}:#{id}")
    |> URI.encode()
    |> Api.get(token, [%User{}])
  end

  def delete_reactions(token, channel_id, message_id) do
    (@root <> channel_id <> "/messages/" <> message_id <> "/reactions")
    |> Api.delete(token)
  end

  def get_channel_invites(token, channel_id) do
    (@root <> channel_id <> "/invites")
    |> Api.get(token, Api.parse_map(Invite))
  end

  def create_channel_invite(token, channel_id, options) do
    (@root <> channel_id <> "/invites")
    |> Api.post(Api.encode(options), token, Invite)
  end

  def delete_channel_permission(token, channel_id, overwrite_id) do
    (@root <> channel_id <> "/permissions/" <> overwrite_id)
    |> Api.delete(token)
  end

  def trigger_typing(token, channel_id) do
    (@root <> channel_id <> "/typing")
    |> Api.post(token)
  end

  def get_pinned_messages(token, channel_id) do
    parser = fn json ->
      json
      |> (fn x -> Parser.parse!(x, %{}) end).()
      |> Enum.map(&Message.from_map/1)
    end

    (@root <> channel_id <> "/pins")
    |> Api.get(token, parser)
  end

  def add_pinned_message(token, channel_id, message_id) do
    (@root <> channel_id <> "/pins/" <> message_id)
    |> Api.put(token)
  end

  def delete_pinned_message(token, channel_id, message_id) do
    (@root <> channel_id <> "/pins/" <> message_id)
    |> Api.delete(token)
  end
end
