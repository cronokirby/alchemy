defmodule Alchemy.Discord.Api do
  alias Alchemy.Discord.RateLimits
  @moduledoc false


  ### Utility ###

  # Converts a keyword list into json
  def encode(options) do
    options |> Enum.into(%{}) |> Poison.encode!
  end

  def query(options) do
    "?" <> Enum.map_join(options, "&", fn {opt, val} ->
      "#{opt}=#{val}"
    end)
  end

  ### Request API ###

  def get(url, token, body) do
    request(:_get, [url, token], body)
  end

  def patch(url, token, data, body) do
    request(:_patch, [url, data, token], body)
  end

  def post(url, token, data, body) do
    request(:_post, [url, data, token], body)
  end
  def post(url, token, data) do
    request(:_post, [url, data, token])
  end

  def delete(url, token) do
    request(:_delete, [url, token])
  end
  def delete(url, token, body) do
    request(:_delete, [url, token], body)
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
    |> handle_response(nil)
  end
  defp request(req_type, req_args, module) when is_atom(module) do
    apply(__MODULE__, req_type, req_args)
    |> handle_response(&apply(module, :from_map, [Poison.Parser.parse!(&1)]))
  end
  defp request(req_type, req_args, parser) when is_function(parser) do
    apply(__MODULE__, req_type, req_args)
    |> handle_response(parser)
  end
  defp request(req_type, req_args, struct) do
    apply(__MODULE__, req_type, req_args)
    |> handle_response(&Poison.decode!(&1, as: struct))
  end


  defmacrop is_ok(code) do
    quote do
      div(unquote(code), 100) == 2
    end
  end


  defp handle_response(%HTTPotion.ErrorResponse{message: why}, _) do
    {:error, why}
  end
  # Ratelimit status code
  defp handle_response(%{status_code: 429} = response, _) do
    RateLimits.rate_info(response)
  end

  defp handle_response(%{status_code: code} = response, nil)
  when is_ok(code) do
    rate_info = RateLimits.rate_info(response)
    {:ok, nil, rate_info}
  end
  defp handle_response(%{status_code: code} = response, decoder)
  when is_ok(code) do
    rate_info = RateLimits.rate_info(response)
    struct = decoder.(response.body)
    {:ok, struct, rate_info}
  end

  defp handle_response(response, _) do
    {:error, response.body}
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

  def _post(url, data, token) do
    HTTPotion.post url, [headers: ["Authorization": "Bot #{token}",
                                    "Content-Type": "application/json"],
                          body: data]
  end

  # Performs a `delete` request, returning an HTTPotion response.
  def _delete(url, token) do
    HTTPotion.delete url, headers: ["Authorization": "Bot #{token}"]
  end

end
