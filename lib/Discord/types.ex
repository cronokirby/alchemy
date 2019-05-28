defmodule Alchemy.Discord.Types do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      @type snowflake :: String.t()
      @type token :: String.t()
      @type url :: String.t()
    end
  end
end
