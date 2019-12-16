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

  test "Check State when a Node is Killed" do
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

    # - Kill NodeA
    NodeHelper.stop(node_a)

    # - Run Command Process in NodeB
    NodeHelper.rpc(
      node_b,
      ":ok = Integration.App.dispatch(%Integration.Commands.Update{uuid: \"#{uuid}\", message: \"update\"})"
    )

    # - Inspect State Aggregate in Node B
    assert {
             %Integration.Aggregate{
               message: "update",
               node: :"b@127.0.0.1",
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


    # Wait for EventHandler to be recreated
    wait_for_event_handler = "(Enum.reduce(1..10, nil, fn _item, acc -> acc || (Process.whereis(Integration.EventHandler) || (Process.sleep(500) && nil)) end))"
    NodeHelper.rpc(node_b, wait_for_event_handler)

    # - Inspect Event Handler Node B
    assert {:"b@127.0.0.1", _} = NodeHelper.rpc(node_b, "Integration.EventHandler.where_am_i")

    # - Inspect State EventHandler in Node B
    assert {%Integration.EventHandler{
              message: "update",
              uuid: uuid
            }, _} = NodeHelper.rpc(node_b, "Integration.EventHandler.state")


    NodeHelper.stop(node_b)
  end

  test "When a node is killed but join again later" do
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

    # - Kill NodeA
    NodeHelper.stop(node_a)

    # - Run Command Process in NodeB
    NodeHelper.rpc(
      node_b,
      ":ok = Integration.App.dispatch(%Integration.Commands.Update{uuid: \"#{uuid}\", message: \"update\"})"
    )

    # Wait for EventHandler to be recreated
    wait_for_event_handler = "(Enum.reduce(1..10, nil, fn _item, acc -> acc || (Process.whereis(Integration.EventHandler) || (Process.sleep(500) && nil)) end))"
    NodeHelper.rpc(node_b, wait_for_event_handler)

    # - Start Node A
    {:ok, node_a} = NodeHelper.start("a")

    # - Connect nodes
    NodeHelper.connect(node_a, node_b)

    # - Run Command Finish in NodeA
    NodeHelper.rpc(
      node_a,
      ":ok = Integration.App.dispatch(%Integration.Commands.Delete{uuid: \"#{uuid}\", message: \"delete\"})"
    )

    # - Inspect State Aggregate in Node B
    assert {
             %Integration.Aggregate{
               message: "delete",
               node: _,
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

    # - Inspect State Aggregate in Node A
    assert {
             %Integration.Aggregate{
               message: "delete",
               node: _,
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


    node_a_result = NodeHelper.rpc(node_a, "Process.whereis(Integration.EventHandler) && Integration.EventHandler.state")
    node_b_result = NodeHelper.rpc(node_b, "Process.whereis(Integration.EventHandler) && Integration.EventHandler.state")

    assert {event_handler_state, _} = Enum.find([node_a_result, node_b_result], fn {item, _} -> is_map(item) end)
    assert %Integration.EventHandler{message: "delete", uuid: uuid} = event_handler_state

    NodeHelper.stop(node_a)
    NodeHelper.stop(node_b)
  end
end
