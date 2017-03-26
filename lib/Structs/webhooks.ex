defmodule Alchemy.Webhooks do
  @moduledoc """
  """

  defstruct [:id,
             :guild_id,
             :channel_id,
             :user,
             :name,
             :avatar,
             :token]
end
