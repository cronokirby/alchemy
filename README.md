# Alchemy

A discord library / framework for elixir.

This library aims to provide a solid foundation, upon which to build
a simple, yet powerful interface. Unlike other libraries, this one comes
along with a framework for defining commands, and event hooks. No need
to mess around with consumers, or handlers, defining a command is as simple
as defining a function!


### Installation
Simply add *Alchemy* to your dependancies in your `mix.exs` file:
```elixir
def deps do
  [{:alchemy, "~> 0.2.0", hex: :discord_alchemy}]
end
```

### [Docs](https://cronokirby.github.io/alchemy-docs/)

This is the stable documentation for the library, I highly recommend going
through it, as most of the relevant information resides there.


### Getting Started
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

Now all we need to do to wire up this application, is to add it to our `mix.exs`:
```elixir
def application do
  [mod: {Mybot, []},
   extra_applications: [:logger]]
end
```
This makes our bot automatically start when we run our project.
Now, to run this project, we have 2 options:
 - use `mix run --no-halt` (the flags being necessary to
   prevent the app from ending once our `start/2` function finishes)
 - or use `iex -S mix` to start our application in the repl.

Starting the application in the repl is very advantageous, as it allows
 you to interact with the bot live.

# Other Examples
If you'd like to see a larger example of a bot using `Alchemy`,
checkout out [Viviani](https://github.com/cronokirby/viviani).
