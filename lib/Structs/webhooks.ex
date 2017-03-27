defmodule Alchemy.Webhooks do
  @moduledoc """
  """
  alias Alchemy.User


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



end
