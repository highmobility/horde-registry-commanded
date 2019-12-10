defmodule IntegrationTest do
  use ExUnit.Case, async: false

  test "start and connect 2 nodes" do
    {:ok, node_a} = NodeHelper.start("a")
    {:ok, node_b} = NodeHelper.start("b")

    {[], _} = NodeHelper.rpc(node_a, "Node.list")
    {[], _} = NodeHelper.rpc(node_b, "Node.list")

    NodeHelper.connect(node_a, node_b)

    {[:"b@127.0.0.1"], _} = NodeHelper.rpc(node_a, "Node.list")
    {[:"a@127.0.0.1"], _} = NodeHelper.rpc(node_b, "Node.list")

    NodeHelper.stop(node_a)
    NodeHelper.stop(node_b)
  end

  test "Run Commands in 2 different Nodes" do
    # - Start NodeA
    {:ok, node_a} = NodeHelper.start("a")
    # - Start NodeB
    {:ok, node_b} = NodeHelper.start("b")
    # - Connect nodes
    NodeHelper.connect(node_a, node_b)

    # - Run Command Start in NodeA
    # NodeHelper.rpc(node_a, "ADD COMMANDED COMMAND HERE")
    # - Run Command Process in NodeB
    # NodeHelper.rpc(node_b, "ADD COMMANDED COMMAND HERE")

    # - Inspect PID NodeA Aggregate
    # - Inspect PID NodeA EventHandler
    # - Inspect PID NodeB Aggregate
    # - Inspect PID NodeB EventHandler
    # - Compare Aggregate and see if they have the correct State
    # - Compare EventHandler and see if they have the correct State

    NodeHelper.stop(node_a)
    NodeHelper.stop(node_b)
  end
end
