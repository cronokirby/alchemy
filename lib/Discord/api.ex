defmodule Alchemy.Discord.Api do
  alias Alchemy.Discord.RateLimits
  @moduledoc false

  # Performs a `get` request for a url, using the provided token as authorization.
  # All discord requests need an authorization token. This info has to be given statically.
  # This doesn't support user accounts atm.
  # Returns a raw HTTPotion `response`.
  def get(url, token) do
    HTTPotion.get url, headers: ["Authorization": "Bot #{token}"]
  end

  # Performs a `patch` request, returning an HTTPotion response.
  # This isn't used too often
  def patch(url, data, token) do
    HTTPotion.patch url, [headers: ["Authorization": "Bot #{token}",
                                    "Content-Type": "application/json"],
                          body: data]
  end

  # Performs a `delete` request, returning an HTTPotion response.
  def delete(url, token) do
    HTTPotion.delete url, headers: ["Authorization": "Bot #{token}"]
  end


  # Fetches an image, encodes it base64, and then formats it in discord's
  # preferred formatting. Returns {:ok, formatted}, or {:error, why}
  def fetch_avatar(url) do
    data = HTTPotion.get(url).body |> Base.encode64
    {:ok, "data:image/jpeg;base64,#{data}"}
  end

  # Performs an HTTP request, of `req_type`, with `req_args`, and then
  # decodes the body using the given struct, and processes the rate_limit information
  # This generic request is specified in later modules.
  def handle_response(%HTTPotion.ErrorResponse{message: why}, _) do
    {:error, why}
  end

  # Ratelimit status code
  def handle_response(%{status_code: 429} = response) do
    RateLimits.rate_info(response)
  end
  def handle_response(response, nil) do
    rate_info = RateLimits.rate_info(response)
    {:ok, :none, rate_info}
  end
  def handle_response(response, struct) do
    rate_info = RateLimits.rate_info(response)
    struct = Poison.decode!(response.body, as: struct)
    {:ok, struct, rate_info}
  end


  def request(req_type, req_args, struct \\ nil) do
    apply(__MODULE__, req_type, req_args)
    |> handle_response(struct)
  end

end
