defmodule Alchemy.Discord.Api do
  alias Alchemy.Discord.RateLimits
  @moduledoc false


  def get(url, token, body_type) do
    request(:_get, [url, token], body_type)
  end

  def patch(url, data, token, body_type) do
    request(:_patch, [url, data, token], body_type)
  end

  def delete(url, token) do
    request(:_delete, [url, token])
  end


  # Fetches an image, encodes it base64, and then formats it in discord's
  # preferred formatting. Returns {:ok, formatted}, or {:error, why}
  def fetch_avatar(url) do
    data = HTTPotion.get(url).body |> Base.encode64
    {:ok, "data:image/jpeg;base64,#{data}"}
  end

  ### Private ###

  defp request(req_type, req_args) do
    apply(__MODULE__, req_type, req_args)
    |> handle_response
  end
  defp request(req_type, req_args, module) when is_atom(module) do
    apply(__MODULE__, req_type, req_args)
    |> handle_response(&apply(module, :from_map, [Poison.Parser.parse!(&1)]))
  end
  defp request(req_type, req_args, struct) do
    apply(__MODULE__, req_type, req_args)
    |> handle_response(&Poison.decode!(&1, as: struct))
  end


  defp handle_response(%HTTPotion.ErrorResponse{message: why}) do
    {:error, why}
  end
  defp handle_response(%HTTPotion.ErrorResponse{message: why}, _) do
    {:error, why}
  end
  # Ratelimit status code
  defp handle_response(%{status_code: 429} = response) do
    RateLimits.rate_info(response)
  end
  defp handle_response(%{status_code: 429} = response, _) do
    RateLimits.rate_info(response)
  end
  defp handle_response(response) do
    rate_info = RateLimits.rate_info(response)
    {:ok, nil, rate_info}
  end
  defp handle_response(response, decoder) do
    rate_info = RateLimits.rate_info(response)
    struct = decoder.(response.body)
    {:ok, struct, rate_info}
  end


  # Performs a `get` request for a url, using the provided token as authorization.
  def _get(url, token) do
    HTTPotion.get url, headers: ["Authorization": "Bot #{token}"]
  end

  # Performs a `patch` request, returning an HTTPotion response.
  # This isn't used too often
  def _patch(url, data, token) do
    HTTPotion.patch url, [headers: ["Authorization": "Bot #{token}",
                                    "Content-Type": "application/json"],
                          body: data]
  end

  # Performs a `delete` request, returning an HTTPotion response.
  def _delete(url, token) do
    HTTPotion.delete url, headers: ["Authorization": "Bot #{token}"]
  end

end
