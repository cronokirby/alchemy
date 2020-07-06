defmodule Alchemy.Discord.Api do
  @moduledoc false
  require Logger
  alias Alchemy.Discord.RateLimits

  ### Utility ###

  # Converts a keyword list into json
  def encode(options) do
    options |> Enum.into(%{}) |> Poison.encode!()
  end

  def query([]) do
    ""
  end

  def query(options) do
    "?" <>
      Enum.map_join(options, "&", fn {opt, val} ->
        "#{opt}=#{val}"
      end)
  end

  # returns a function to be used in api requests
  def parse_map(mod) do
    fn json ->
      json
      |> (fn x -> Poison.Parser.parse!(x, %{}) end).()
      |> Enum.map(&mod.from_map/1)
    end
  end

  ### Request API ###

  def get(url, token, body) do
    request(:get, url, token)
    |> handle(body)
  end

  def patch(url, token, data \\ "", body \\ :no_parser) do
    request(:patch, url, data, token)
    |> handle(body)
  end

  def post(url, token, data \\ "", body \\ :no_parser) do
    request(:post, url, data, token)
    |> handle(body)
  end

  def put(url, token, data \\ "") do
    request(:put, url, data, token)
    |> handle(:no_parser)
  end

  def delete(url, token, body \\ :no_parser) do
    request(:delete, url, token)
    |> handle(body)
  end

  def image_data(url) do
    {:ok, HTTPoison.get(url).body |> Base.encode64()}
  end

  # Fetches an image, encodes it base64, and then formats it in discord's
  # preferred formatting. Returns {:ok, formatted}, or {:error, why}
  def fetch_avatar(url) do
    {:ok, data} = image_data(url)
    {:ok, "data:image/jpeg;base64,#{data}"}
  end

  ### Private ###

  # gets the auth headers, checking for selfbot
  def auth_headers(token) do
    client_type = Application.get_env(:alchemy, :self_bot, "Bot ")

    [
      {"Authorization", client_type <> "#{token}"},
      {"User-Agent", "DiscordBot (https://github.com/cronokirby/alchemy, 0.6.0)"}
    ]
  end

  def request(type, url, token) do
    apply(HTTPoison, type, [url, auth_headers(token)])
  end

  def request(type, url, data, token) do
    headers = auth_headers(token)
    headers = [{"Content-Type", "application/json"} | headers]
    headers = [{"X-RateLimit-Precision", "millisecond"} | headers]
    apply(HTTPoison, type, [url, data, headers])
  end

  def handle(response, :no_parser) do
    handle_response(response, :no_parser)
  end

  def handle(response, module) when is_atom(module) do
    handle_response(response, &module.from_map(Poison.Parser.parse!(&1, %{})))
  end

  def handle(response, parser) when is_function(parser) do
    handle_response(response, parser)
  end

  def handle(response, struct) do
    handle_response(response, &Poison.decode!(&1, as: struct))
  end

  defp handle_response({:error, %HTTPoison.Error{reason: why}}, _) do
    {:error, why}
  end

  # Ratelimit status code
  defp handle_response({:ok, %{status_code: 429} = response}, _) do
    RateLimits.rate_info(response)
  end

  defp handle_response({:ok, %{status_code: code} = response}, :no_parser)
       when code in 200..299 do
    rate_info = RateLimits.rate_info(response)
    {:ok, nil, rate_info}
  end

  defp handle_response({:ok, %{status_code: code} = response}, decoder)
       when code in 200..299 do
    rate_info = RateLimits.rate_info(response)
    struct = decoder.(response.body)
    {:ok, struct, rate_info}
  end

  defp handle_response({:ok, response}, _) do
    {:error, response.body}
  end

  # This is necessary in a few places to bypass the error handling:
  # i.e. the Gateway url requests.
  def get!(url) do
    HTTPoison.get!(url)
  end

  def get!(url, token) do
    HTTPoison.get!(url, auth_headers(token))
  end
end
