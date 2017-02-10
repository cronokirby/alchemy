defmodule Alchemy.Discord.EventManager do
   alias Alchemy.Discord.EventHandler
   use Supervisor
   @moduledoc false
   # Acts as an event dispatcher, that children can be dynamically started from.
   # Sort of akin to a GenEvent, but each child is it's own process
   # When writing this module I assume their will only ever need to be one of it.

   # name will be assigned by the client supervisor
   def start_link(opts) do
     Supervisor.start_link(__MODULE__, [], opts)
   end


   def init([]) do
     children = [
       worker(Event, [])
     ]
     supervise(children, strategy: :simple_one_for_one)
   end

   # adds a new handle with a name, event_type, module, and method
   def add_handle(args) do
     Supervisor.start_child(Events, args)
   end

   # Recasts the message to all the handlers
   def notify(msg) do
     for {_, pid, _, _} <- Supervisor.which_children(Events) do
       GenServer.cast(pid, msg)
     end
   end
end
