defmodule Mix.Tasks.Alchemy.Init do
  def run(_) do
    File.write("lib/mybot.ex", """
    defmodule MyBot do
      use Application
      alias Alchemy.Client

      defmodule Commands do
        use Alchemy.Cogs

        Cogs.def ping do
          Cogs.say "pong!"
        end
      end

      def start(_type, _args) do
        run = Client.start("your token here")
        use Commands
        run
      end
    end
    """)

    IO.puts("""
    An example bot has been generated in `lib/mybot.ex`.
    Next, add your token to line 14 of that file, and modify mix.exs to contain the following:
      def application do
        [mod: {MyBot, []}]
      end
    """)
  end
end
