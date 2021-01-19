defmodule Alchemy.Voice.SupervisorTest do
  use ExUnit.Case, async: true
  alias Alchemy.Voice.Supervisor, as: VoiceSupervisor

  setup do
    pid =
      case Process.whereis(VoiceSupervisor) do
        nil ->
          {:ok, pid} = VoiceSupervisor.start_link()
          pid

        pid ->
          pid
      end

    {:ok, supervisor: pid}
  end

  test "re-registering doesn't work", %{supervisor: supervisor} do
    assert GenServer.call(VoiceSupervisor.Server, {:start_client, 1}) == :ok
    bad_resp = GenServer.call(VoiceSupervisor.Server, {:start_client, 1})
    refute bad_resp == :ok

    cleanup(supervisor)
  end

  test "different channels do work", %{supervisor: supervisor} do
    assert GenServer.call(VoiceSupervisor.Server, {:start_client, 3}) == :ok
    assert GenServer.call(VoiceSupervisor.Server, {:start_client, 4}) == :ok

    cleanup(supervisor)
  end

  defp cleanup(supervisor) do
    Supervisor.stop(supervisor)
  end
end
