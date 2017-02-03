defmodule Alchemy.Discord.Api do
  @moduledoc """
  The base helper for discord requests
  """
  @doc """
  Performs a `get` request for a url, using the provided token as authorization.
  
  All discord requests need an authorization token. This info has to be given statically.
  This doesn't support user accounts atm.

  Returns a raw HTTPotion `response`.
  """
  def get(url, token) do
    HTTPotion.get url, headers: [Authorization: "Bot #{token}"]
  end

end
