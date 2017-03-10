defmodule Alchemy.Discord.Guilds do
  @moduledoc false
  alias Alchemy.Discord.Api
  alias Alchemy.{Channel, Guild, GuildMember}

  @root "https://discordapp.com/api/v6/guilds/"


  # returns information for a current guild; cache should be preferred over this
  def get_guild(token, guild_id) do
    Api.get(@root <> guild_id, token, Guild)
  end


  def modify_guild(token, guild_id, options) do
    Api.patch(@root <> guild_id, token, Api.encode(options), Guild)
  end


  def get_channels(token, guild_id) do
    @root <> guild_id <> "/channels"
    |> Api.get(token, Api.parse_map(&Guild.from_map/1))
  end


  def create_channel(token, guild_id, name, options) do
    options = Keyword.put(options, :name, name)
              |> Api.encode
    @root <> guild_id <> "/channels"
    |> Api.post(token, options, Channel)
  end


  def move_channels(token, guild_id, tuples) do
    channels = Stream.map(tuples, fn {id, pos} ->
      %{id: id, position: pos}
    end) |> Api.encode
    @root <> guild_id <> "/channels"
    |> Api.patch(token, channels, Api.parse_map(&Channel.from_map/1))
  end


  def get_member(token, guild_id, user_id) do
    @root <> guild_id <> "/members/" <> user_id
    |> Api.get(token, GuildMember)
  end


  def get_member_list(token, guild_id, options) do
    @root <> guild_id <> "/members" <> URI.encode_query(options)
    |> Api.get(token, Api.parse_map(&GuildMember.from_map/1))
  end
end
