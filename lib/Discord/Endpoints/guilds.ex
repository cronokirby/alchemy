defmodule Alchemy.Discord.Guilds do
  @moduledoc false
  alias Alchemy.Discord.Api
  alias Alchemy.{Channel, Invite, Guild, User, VoiceRegion}
  alias Alchemy.Guild.{GuildMember, Integration, Role}
  alias Alchemy.AuditLog

  @root "https://discord.com/api/v6/guilds/"

  # returns information for a current guild; cache should be preferred over this
  def get_guild(token, guild_id) do
    Api.get(@root <> guild_id, token, Guild)
  end

  def modify_guild(token, guild_id, options) do
    options =
      options
      |> Keyword.take([:icon, :splash])
      |> Task.async_stream(fn {k, v} -> {k, Api.image_data(v)} end)
      |> Enum.map(fn {:ok, v} -> v end)
      |> Keyword.merge(options)

    Api.patch(@root <> guild_id, token, Api.encode(options), Guild)
  end

  def get_channels(token, guild_id) do
    (@root <> guild_id <> "/channels")
    |> Api.get(token, Api.parse_map(Channel))
  end

  def create_channel(token, guild_id, name, options) do
    options =
      case Keyword.get(options, :voice) do
        true ->
          {_, o} = Keyword.pop(options, :voice)
          Keyword.put(o, :type, 2)

        _ ->
          options
      end
      |> Keyword.put(:name, name)
      |> Api.encode()

    (@root <> guild_id <> "/channels")
    |> Api.post(token, options, Channel)
  end

  def move_channels(token, guild_id, tuples) do
    channels =
      Stream.map(tuples, fn {id, pos} ->
        %{"id" => id, "position" => pos}
      end)
      |> Poison.encode!()

    (@root <> guild_id <> "/channels")
    |> Api.patch(token, channels)
  end

  def get_member(token, guild_id, user_id) do
    (@root <> guild_id <> "/members/" <> user_id)
    |> Api.get(token, GuildMember)
  end

  def get_member_list(token, guild_id, options) do
    query =
      case URI.encode_query(options) do
        "" -> ""
        q -> "?" <> q
      end

    (@root <> guild_id <> "/members" <> query)
    |> Api.get(token, Api.parse_map(GuildMember))
  end

  def modify_member(token, guild_id, user_id, options) do
    (@root <> guild_id <> "/members/" <> user_id)
    |> Api.patch(token, Api.encode(options))
  end

  def modify_nick(token, guild_id, nick) do
    json = ~s/{"nick": #{nick}}/

    (@root <> guild_id <> "/members/@me/nick")
    |> Api.patch(token, json)
  end

  def add_role(token, guild_id, user_id, role_id) do
    (@root <> guild_id <> "/members/" <> user_id <> "/roles/" <> role_id)
    |> Api.put(token)
  end

  def remove_role(token, guild_id, user_id, role_id) do
    (@root <> guild_id <> "/members/" <> user_id <> "/roles/" <> role_id)
    |> Api.delete(token)
  end

  def remove_member(token, guild_id, user_id) do
    (@root <> guild_id <> "/members/" <> user_id)
    |> Api.delete(token)
  end

  def get_bans(token, guild_id) do
    (@root <> guild_id <> "/bans")
    |> Api.get(token, Api.parse_map(User))
  end

  def create_ban(token, guild_id, user_id, days) do
    json = ~s/{"delete-message-days": #{days}}/

    (@root <> guild_id <> "/bans/" <> user_id)
    |> Api.put(token, json)
  end

  def remove_ban(token, guild_id, user_id) do
    (@root <> guild_id <> "/bans/" <> user_id)
    |> Api.delete(token)
  end

  def get_roles(token, guild_id) do
    (@root <> guild_id <> "/roles")
    |> Api.get(token, [%Role{}])
  end

  def create_role(token, guild_id, options) do
    (@root <> guild_id <> "/roles")
    |> Api.post(token, Api.encode(options), %Role{})
  end

  def move_roles(token, guild_id, tuples) do
    roles =
      Stream.map(tuples, fn {id, pos} ->
        %{id: id, position: pos}
      end)
      |> Api.encode()

    (@root <> guild_id <> "/roles")
    |> Api.patch(token, roles, [%Role{}])
  end

  def modify_role(token, guild_id, role_id, options) do
    (@root <> guild_id <> "/roles/" <> role_id)
    |> Api.patch(token, Api.encode(options), %Role{})
  end

  def delete_role(token, guild_id, role_id) do
    (@root <> guild_id <> "/roles/" <> role_id)
    |> Api.delete(token)
  end

  def get_prune_count(token, guild_id, days) do
    (@root <> guild_id <> "/prune?" <> URI.encode_query(%{"days" => days}))
    |> Api.get(token, & &1["pruned"])
  end

  def prune_guild(token, guild_id, days) do
    json = ~s/{"days": #{days}}/

    (@root <> guild_id <> "/prune")
    |> Api.post(token, json)
  end

  def get_regions(token, guild_id) do
    (@root <> guild_id <> "/regions")
    |> Api.get(token, [%VoiceRegion{}])
  end

  def get_invites(token, guild_id) do
    (@root <> guild_id <> "/invites")
    |> Api.get(token, Api.parse_map(Invite))
  end

  def get_all_regions(token) do
    "https://discord.com/api/v6/voice/regions"
    |> Api.get(token, [%VoiceRegion{}])
  end

  def get_integrations(token, guild_id) do
    (@root <> guild_id <> "/integrations")
    |> Api.get(token, Api.parse_map(Integration))
  end

  def edit_integration(token, guild_id, integration_id, options) do
    (@root <> guild_id <> "/integrations/" <> integration_id)
    |> Api.patch(token, Api.encode(options))
  end

  def delete_integration(token, guild_id, integration_id) do
    (@root <> guild_id <> "/integrations/" <> integration_id)
    |> Api.delete(token)
  end

  def sync_integration(token, guild_id, integration_id) do
    (@root <> guild_id <> "/integrations/" <> integration_id <> "/sync")
    |> Api.post(token)
  end

  def get_audit_log(token, guild_id, options) do
    (@root <> guild_id <> "/audit-log?" <> URI.encode_query(options))
    |> Api.get(token, AuditLog)
  end
end
