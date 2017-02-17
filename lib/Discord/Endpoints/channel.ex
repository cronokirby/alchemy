defmodule Alchemy.Discord.Channel do
  alias Alchemy.Discord.Api
  alias Alchemy.{Channel, DMChannel}
  import Alchemy.Structs.Utility
  @moduledoc false

  @root "https://discordapp.com/api/users/"


  def get_channel(token, chan_id) do
    parser = fn json ->
      parsed = Poison.Parser.parse!(json)
      if parsed["is_private"] do
        to_struct(parsed, DMChannel)
      else
        Channel.from_map(parsed)
      end
    end
    Api.get(@root <> chan_id, parser)
  end


  def modify_channel(token, channel_id, options) do
    json = options |> Enum.into(%{}) |> Poison.encode!
    Api.patch(@root <> channel_id, token, json, Channel)
  end
end
