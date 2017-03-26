defmodule Alchemy.EventMacros do
  @moduledoc false
  # Since this pattern is repeated for all 20 event handles, having this is conveniant.
  defmacro handle(type, func) do
    quote bind_quoted: [type: type, func: func] do
      quote do
        @handles [{unquote(type), {__MODULE__, unquote(func)}} | @handles]
      end
    end
  end
end
