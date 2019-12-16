defmodule HordeRegistryCommanded.NodeListener do
  @moduledoc false
  use GenServer

  @member_name HordeRegistryCommanded.HordeRegistry

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, opts)
  end

  @impl true
  def init(_opts) do
    :net_kernel.monitor_nodes(true, node_type: :visible)

    {:ok, nil}
  end

  @impl true
  def handle_continue(:initialize, state) do
    set_members()

    {:noreply, state}
  end

  @impl true
  def handle_info({:nodeup, _node, _}, state) do
    set_members()

    {:noreply, state}
  end

  @impl true
  def handle_info({:nodedown, _node, _}, state) do
    set_members()

    {:noreply, state}
  end

  def members(name) do
    nodes = [Node.self() | Node.list()]
    Enum.map(nodes, fn node -> {name, node} end)
  end

  defp set_members() do
    :ok = Horde.Cluster.set_members(@member_name, members(@member_name))
  end
end
