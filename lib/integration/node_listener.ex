defmodule Integration.NodeListener do
  @moduledoc false
  use GenServer

  @member_names [
    Integration.HordeRegistry,
    Integration.DistributedSupervisor
  ]

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, opts)
  end

  @impl true
  def init(opts) do
    :net_kernel.monitor_nodes(true, node_type: :visible)

    state = %{mfa: Keyword.get(opts, :invoke)}

    {:ok, state, {:continue, :initialize}}
  end

  @impl true
  def handle_continue(:initialize, state) do
    set_members()

    invoke(state.mfa)

    {:noreply, state}
  end

  def invoke({m, f, a}) do
    apply(m, f, a)
  end

  def invoke(_), do: nil

  @impl true
  def handle_info({:nodeup, _node, _}, state) do
    set_members()

    {:noreply, state}
  end

  @impl true
  def handle_info({:nodedown, _node, _}, state) do
    set_members()

    invoke(state.mfa)

    {:noreply, state}
  end

  def members(name) do
    nodes = [Node.self() | Node.list()]
    Enum.map(nodes, fn node -> {name, node} end)
  end

  defp set_members() do
    Enum.each(@member_names, fn name ->
      :ok = Horde.Cluster.set_members(name, members(name))
    end)
  end
end
