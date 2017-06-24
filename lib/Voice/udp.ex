defmodule Alchemy.Voice.UDP do
  @moduledoc false

  def open_udp(endpoint, port, ssrc) do
    discord_ip = resolve(endpoint)
    IO.inspect discord_ip
    data = <<ssrc :: size(560)>>
    udp_opts = [:binary, active: false, reuseaddr: true]
    {:ok, udp} = :gen_udp.open(0, udp_opts)
    :gen_udp.send(udp, discord_ip, port, data)
    {:ok, discovery} = :gen_udp.recv(udp, 70)
    <<_padding :: size(32), my_ip :: bitstring-size(112),
      _null :: size(400), my_port :: size(16)>> =
        discovery |> Tuple.to_list |> List.last
    {my_ip, my_port, discord_ip, udp}
  end

  defp resolve(endpoint) do
    endpoint
    |> String.to_charlist
    |> :inet_res.resolve(:in, :a, [nameservers: [{{8,8,8,8},53}]])
    |> elem(1) |> elem(3) |> hd |> elem(6) # black magic
  end
end
