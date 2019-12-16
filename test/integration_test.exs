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

  test "Run Commands in a non-distributed node" do
    # - Start NodeA
    {:ok, node_a} = NodeHelper.start("a")

    uuid = UUID.uuid4()

    # - Run Command Start
    NodeHelper.rpc(
      node_a,
      ":ok = Integration.App.dispatch(%Integration.Commands.Create{uuid: \"#{uuid}\", message: \"create\"})"
    )

    # - Inspect State Aggregate
    assert {
             %Integration.Aggregate{message: "create", uuid: uuid},
             _
           } =
             NodeHelper.rpc(
               node_a,
               "Commanded.Aggregates.Aggregate.aggregate_state(Integration.App, Integration.Aggregate, \"#{
                 uuid
               }\")"
             )

    # - Inspect State EventHandler
    assert {%Integration.EventHandler{
              message: "create",
              uuid: uuid
            }, _} = NodeHelper.rpc(node_a, "Integration.EventHandler.state")

    NodeHelper.stop(node_a)
  end

  test "Run Commands in 2 different Nodes" do
    # - Start Nodes
    {:ok, node_a} = NodeHelper.start("a")
    {:ok, node_b} = NodeHelper.start("b")

    # - Connect nodes
    NodeHelper.connect(node_a, node_b)

    uuid = UUID.uuid4()

    # - Run Command Start in NodeA
    NodeHelper.rpc(
      node_a,
      ":ok = Integration.App.dispatch(%Integration.Commands.Create{uuid: \"#{uuid}\", message: \"create\"})"
    )

    # - Run Command Process in NodeB
    NodeHelper.rpc(
      node_b,
      ":ok = Integration.App.dispatch(%Integration.Commands.Update{uuid: \"#{uuid}\", message: \"update\"})"
    )

    # - Inspect State Aggregate in Node A
    assert {
             %Integration.Aggregate{
               message: "update",
               node: :"a@127.0.0.1",
               uuid: uuid
             },
             0
           } =
             NodeHelper.rpc(
               node_a,
               "Commanded.Aggregates.Aggregate.aggregate_state(Integration.App, Integration.Aggregate, \"#{
                 uuid
               }\")"
             )

    # - Inspect State Aggregate in Node B
    assert {
             %Integration.Aggregate{
               message: "update",
               node: :"a@127.0.0.1",
               uuid: uuid
             },
             0
           } =
             NodeHelper.rpc(
               node_b,
               "Commanded.Aggregates.Aggregate.aggregate_state(Integration.App, Integration.Aggregate, \"#{
                 uuid
               }\")"
             )

    # - Inspect Event Handler Node A
    assert {:"a@127.0.0.1", _} = NodeHelper.rpc(node_a, "Integration.EventHandler.where_am_i")

    # # - Inspect State EventHandler in Node A
    assert {%Integration.EventHandler{
              message: "update",
              uuid: uuid
            }, _} = NodeHelper.rpc(node_a, "Integration.EventHandler.state")

    # - Inspect Event Handler Node B
    assert {nil, _} = NodeHelper.rpc(node_b, "Process.whereis(Integration.EventHandler)")

    NodeHelper.stop(node_a)
    NodeHelper.stop(node_b)
  end
end
