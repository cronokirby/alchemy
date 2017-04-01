# Getting Started
After installing your dependancies and whatnot, it's time to write your bot!

The first thing we need to do is define some kind of application for our bot.
Thankfully, the `Application` module encapsulates this need.
```elixir
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
```
So we defined what we call a `Cog` in the `Commands` module, a cog
is simply a module that contains commands. To wire up this command into the bot,
we need to `use` the module, which we do after starting the client. We need
to provide a valid return type in `start/2`, which is why we capture the result
of `Client.start` in a variable.

### Adding the application to our `mix`

Now all we need to do to wire up this application, is to add it to our `mix.exs`:
```elixir
def application do
  [mod: {Mybot, []},
   extra_applications: [:logger]]
end
```

### Running our application

This makes our bot automatically start when we run our project.
Now, to run this project, we have 2 options:
 - use `mix run --no-halt` (the flags being necessary to
   prevent the app from ending once our `start/2` function finishes)
 - or use `iex -S mix` to start our application in the repl.

Starting the application in the repl is very advantageous, as it allows
 you to interact with the bot live.


### Where to go now
I'd recommend taking a look at the `Alchemy.Cogs` module for more examples
of defining commands, and how to make use of pattern matching in them.

If you want to learn about event hooks, check out the `Alchemy.Events` module.

If you want to dig through the many api functions available, check out
`Alchemy.Client`.
