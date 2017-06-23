defmodule Alchemy.Voice.SupervisorTest do
  use ExUnit.Case, async: true
  alias Alchemy.Voice.Supervisor

  setup do
    {:ok, supervisor} = Supervisor.start_link()
    {:ok, supervisor: supervisor}
  end

  test "re-registering doesn't work" do
    assert GenServer.call(Supervisor.Server, {:start_client, 1}) == :ok
    bad_resp = GenServer.call(Supervisor.Server, {:start_client, 1})
    refute bad_resp == :ok
  end

  test "different channels do work" do
    assert GenServer.call(Supervisor.Server, {:start_client, 3}) == :ok
    assert GenServer.call(Supervisor.Server, {:start_client, 4}) == :ok
  end
end
