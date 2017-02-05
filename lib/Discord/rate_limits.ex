defmodule Alchemy.Discord.RateLimits do
  @moduledoc false
  # Used for parsing ratelimits out of headers

  defmodule RateInfo do
    @moduledoc false
    defstruct [:limit, :remaining, :reset_time]
  end

  def rate_info(%HTTPotion.Response{status_code: 200, headers: h}) do
    headers = h.hdrs
    case headers["x-ratelimit-remaining"] do
      nil -> # Catches a missing key, meaning no rate limit on that path
        :none
      remaining ->
        {remaining, _} = Integer.parse remaining
        {reset_time, _} = Integer.parse headers["x-ratelimit-reset"]
        {limit, _} = Integer.parse headers["x-ratelimit-limit"]
        %RateInfo{limit: limit, remaining: remaining, reset_time: reset_time}
    end
  end

  # Used the first time a bucket is accessed during the program
  # It makes it so that in the case of multiple processes getting sent at the same time
  # to a virgin bucket, they'll have to wait for the first one to clear through,
  # and get rate info.
  def default_info do
    now = DateTime.utc_now |> DateTime.to_unix
    # 2 seconds should be enough to let the first one get a clean request
    %RateInfo{limit: 0, remaining: 1, reset_time: now + 2}
  end
end
