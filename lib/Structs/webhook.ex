defmodule Alchemy.Webhook do
  @moduledoc """
  """
  alias Alchemy.Discord.Webhooks
  alias Alchemy.User
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


  def create(channel_id, name, options \\ []) do
    {Webhooks, :create_webhook, [channel_id, name, options]}
    |> send_req("/channels/webhooks")
  end

end
