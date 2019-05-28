defmodule Alchemy.Discord.Payloads do
  @moduledoc false
  # These contain functions that construct payloads.
  # For deconstruction, see Alchemy.Discord.Events

  def opcode(op) do
    %{
      dispatch: 0,
      heartbeat: 1,
      identify: 2,
      status_update: 3,
      voice_update: 4,
      voice_ping: 5,
      resume: 6,
      reconnect: 7,
      req_guild_members: 8,
      invalid: 9,
      hello: 10,
      ACK: 11
    }[op]
  end

  # Constructs a sendable payload string, from an opcode, and data, in map form
  def build_payload(op, data) do
    payload = %{op: opcode(op), d: data}
    Poison.encode!(payload)
  end

  def properties(os) do
    %{
      "$os" => os,
      "$browser" => "alchemy",
      "$device" => "alchemy",
      "$referrer" => "",
      "$referring_domain" => ""
    }
  end

  def identify_msg(token, shard) do
    {os, _} = :os.type()

    identify = %{
      token: token,
      properties: properties(os),
      compress: true,
      large_threshold: 250,
      shard: shard
    }

    build_payload(:identify, identify)
  end

  def resume_msg(state) do
    resume = %{token: state.token, session_id: state.session_id, seq: state.seq}
    build_payload(:resume, resume)
  end

  def heartbeat(seq) do
    build_payload(:heartbeat, seq)
  end

  def status_update(idle_since, info) do
    game =
      case info do
        nil ->
          nil

        {:streaming, game_name, twitch} ->
          %{name: game_name, type: 1, url: "https://twitch.tv/" <> twitch}

        {:playing, game_name} ->
          %{name: game_name, type: 0}
      end

    payload = %{since: idle_since, game: game}
    build_payload(:status_update, payload)
  end

  def request_guild_members(guild_id, username, limit) do
    payload = %{guild_id: guild_id, query: username, limit: limit}
    build_payload(:req_guild_members, payload)
  end

  def voice_update(guild_id, channel_id, mute, deaf) do
    payload = %{guild_id: guild_id, channel_id: channel_id, self_mute: mute, self_deaf: deaf}
    build_payload(:voice_update, payload)
  end
end
