defmodule Mix.Tasks.Alchemy.Init do
  def run(_) do
    File.write("lib/mybot.ex", 
      """
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
      Next, add your token to line 16 of lib/mybot.ex and modify mix.exs to contain the following:
        def application do
          [mod: {Mybot, []}]
        end
        """)
  end
end
