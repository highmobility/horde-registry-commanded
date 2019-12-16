defmodule Integration.Cluster do
  @moduledoc false

  def stop(node) do
    :slave.stop(node)
  end

  def prepare do
    # Turn node into a distributed node with the given long name
    :net_kernel.start([:"primary@127.0.0.1"])

    # Allow spawned nodes to fetch all code from this node
    :erl_boot_server.start([])
    {:ok, ipv4} = :inet.parse_ipv4_address('127.0.0.1')
    :erl_boot_server.add_slave(ipv4)
  end

  def spawn(node) do
    # Start Node
    {:ok, node} =
      :slave.start(
        '127.0.0.1',
        node,
        '-loader inet -hosts 127.0.0.1 -setcookie #{:erlang.get_cookie()}'
      )

    :rpc.block_call(node, :code, :add_paths, [:code.get_path()])

    # Start Mix
    :rpc.block_call(node, Application, :ensure_all_started, [:mix])
    :rpc.block_call(node, Mix, :env, [:dev])

    # Load Personalized Config
    for {key, val} <-
          Keyword.get(
            :rpc.block_call(node, Config.Reader, :read!, ["config/worker.exs"]),
            :integration
          ) do
      :rpc.block_call(node, Application, :put_env, [:integration, key, val])
    end

    # Start Apps
    for {app_name, _, _} <- Application.loaded_applications() do
      :rpc.block_call(node, Application, :ensure_all_started, [app_name])
    end

    {:ok, node}
  end
end
