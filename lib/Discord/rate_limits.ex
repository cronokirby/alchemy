defmodule Alchemy.Discord.RateLimits do
  @moduledoc false
  # Used for parsing ratelimits out of headers
  require Logger

  defmodule RateInfo do
    @moduledoc false
    defstruct [:limit, :remaining, :reset_time]
  end

  # will only match if the ratelimits are present
  defp parse_headers(%{"X-RateLimit-Remaining" => remaining} = headers) do
    {remaining, _} = Integer.parse(remaining)
    {reset_time, _} = Integer.parse(headers["X-RateLimit-Reset"])
    {limit, _} = Integer.parse(headers["X-RateLimit-Limit"])
    %RateInfo{limit: limit, remaining: remaining, reset_time: reset_time}
  end

  defp parse_headers(_none) do
    nil
  end

  # status code empty
  def rate_info(%{status_code: 204}) do
    nil
  end

  def rate_info(%{status_code: 200, headers: h}) do
    h |> Enum.into(%{}) |> parse_headers
  end

  # Used in the case of a 429 error, expected to "decide" what response to give
  def rate_info(%{status_code: 429, headers: h, body: body}) do
    body = Poison.Parser.parse!(body, %{})
    timeout = body["retry_after"]

    if body["global"] do
      {:global, timeout}
    else
      {:local, timeout, h |> Enum.into(%{}) |> parse_headers}
    end
  end

  # Used the first time a bucket is accessed during the program
  # It makes it so that in the case of multiple processes getting sent at the same time
  # to a virgin bucket, they'll have to wait for the first one to clear through,
  # and get rate info.
  def default_info do
    now = DateTime.utc_now() |> DateTime.to_unix()
    # 2 seconds should be enough to let the first one get a clean request
    %RateInfo{limit: 1, remaining: 1, reset_time: now + 2}
  end
end
