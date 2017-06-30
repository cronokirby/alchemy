defmodule Alchemy.Cogs.ArgParser.ParseTest do
  use ExUnit.Case, async: true
  alias Alchemy.Cogs.CommandHandler.ArgParser

  test "parsing with random quotes and whitespace" do
    args = ArgParser.parse(~s/ ab"xy.  ye"om"izi\\" xe"zcse"lo ase"be  43  xd  1.2.3.4 "tons" more here ""/)
    assert args == [~s/abxy.  yeomizi" xezcselo asebe/, "43", "xd", "1.2.3.4", "tons", "more", "here", ""]
  end
end