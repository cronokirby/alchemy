defmodule Alchemy.Discord.Api do
  @moduledoc false
  require Logger
  alias Alchemy.Discord.RateLimits

  ### Utility ###

  # Converts a keyword list into json
  def encode(options) do
    options |> Enum.into(%{}) |> Poison.encode!
  end


  def query([]) do
    ""
  end
  def query(options) do
    "?" <> Enum.map_join(options, "&", fn {opt, val} ->
      "#{opt}=#{val}"
    end)
  end

  # returns a function to be used in api requests
  def parse_map(mod) do
    fn json ->
      json
      |> Parser.parse!
      |> Enum.map(&mod.from_map/1)
    end
  end

  ### Request API ###


  def get(url, token, body) do
    request(:_get, [url, token], body)
  end


  def patch(url, token, data, body) do
    request(:_patch, [url, data, token], body)
  end


  def post(url, token) do
    request(:_post, [url, token])
  end
  def post(url, token, data) do
    request(:_post, [url, data, token])
  end
  def post(url, token, data, body) do
    request(:_post, [url, data, token], body)
  end


  def put(url, token) do
    request(:_put, [url, token])
  end
  def put(url, token, body) do
    request(:_put, [url, token], body)
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
    |> handle_response(&module.from_map(Poison.Parser.parse!(&1)))
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
      unquote(code) in 200..299
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


  # gets the auth headers, checking for selfbot
  def auth_headers(token) do
    client_type = Application.get_env(:alchemy, :self_bot, "Bot ")
    ["Authorization": client_type <> "#{token}"]
  end
  # Performs a `get` request for a url, using the provided token as authorization.
  def _get(url) do
    HTTPotion.get url
  end
  def _get(url, token) do
    HTTPotion.get url,
      headers: auth_headers(token)
  end

  # Performs a `patch` request, returning an HTTPotion response.
  # This isn't used too often
  def _patch(url, data, token) do
    HTTPotion.patch url,
      [headers: auth_headers(token) ++
                ["Content-Type": "application/json"],
      body: data]
  end


  def _post(url, token) do
    HTTPotion.post url,
      headers: auth_headers(token)
  end
  def _post(url, data, token) do
    HTTPotion.post url,
      [headers: auth_headers(token) ++
                ["Content-Type": "application/json"],
      body: data]
  end


  def _put(url, token) do
    HTTPotion.put url,
      headers: auth_headers(token)
  end


  # Performs a `delete` request, returning an HTTPotion response.
  def _delete(url, token) do
    HTTPotion.delete url,
      headers: auth_headers(token)
  end

end
