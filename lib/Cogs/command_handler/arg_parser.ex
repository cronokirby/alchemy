defmodule Alchemy.Cogs.CommandHandler.ArgParser do
  def parse(rest) do
    Enum.reverse(parse([], rest))
  end

  defp parse(args, "") do
    args
  end

  defp parse(args, rest) do
    rest = String.trim_leading(rest)
    {arg, rest} = next_arg(rest)
    arg = String.replace(arg, ~s/\\"/, ~s/"/)
    args = [arg | args]
    parse(args, rest)
  end

  defp next_arg(rest) do
    space_index = find_next_space(rest)
    quote_index = find_next_quote(rest)
    cond do
      # If they are the same, they are both nil.
      space_index == quote_index ->
        {rest, ""}
      quote_index == nil or space_index < quote_index ->
        {arg, " " <> rest} = String.split_at(rest, space_index)
        {arg, rest}
      true ->
        # No String.split with regex because it will delete the character behind the quote.
        {arg, ~s/"/ <> rest} = String.split_at(rest, quote_index)
        case find_next_quote(rest) do
          -1 -> {arg <> rest, ""}
          quote_index ->
            {arg2, ~s/"/ <> rest} = String.split_at(rest, quote_index)
            arg = arg <> arg2
            case rest do
              " " <> rest -> {arg, rest}
              rest ->
                {arg3, rest} = next_arg(rest)
                {arg <> arg3, rest}
            end
        end
    end
  end

  defp find_next(regex, rest) do
    case Regex.run(regex, rest, return: :index) do
      [{index, _length}] -> index
      nil -> nil
    end
  end

  defp find_next_space(rest) do
    find_next(~r/ /, rest)
  end

  defp find_next_quote(~s/"/ <> _rest) do
    0
  end

  defp find_next_quote(rest) do
    # Matches all quotes not preceeded by a slash.
    case find_next(~r/[^\\]"/, rest) do
      nil -> nil
      quote_index ->
         # Index points to character before quote.
         # So increment it.
         quote_index + 1
    end
  end
end