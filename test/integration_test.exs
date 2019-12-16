defmodule IntegrationTest do
  use ExUnit.Case, async: false

  def clear_db do
    config = Integration.EventStore.config()
    :ok = EventStore.Tasks.Drop.exec(config, [])
    :ok = EventStore.Tasks.Create.exec(config, [])
    :ok = EventStore.Tasks.Init.exec(Integration.EventStore, config, [])
  end

  def rpc(node, module, function, arguments) do
    ##
    # TODO: Pass PID to command/event so test can know when it was processed
    ##
    a = :rpc.block_call(node, module, function, arguments)
    Process.sleep(100)
    a
  end

  setup_all do
    clear_db()

    Integration.Cluster.prepare()
  end

  setup do
    on_exit(fn ->
      Enum.each(Node.list(), fn node ->
        Integration.Cluster.stop(node)
      end)
    end)
  end

  test "start and connect 2 nodes" do
    {:ok, node_a} = Integration.Cluster.spawn(:node_a)
    {:ok, node_b} = Integration.Cluster.spawn(:node_b)

    assert [:"primary@127.0.0.1", :"node_b@127.0.0.1"] = :rpc.block_call(node_a, Node, :list, [])
    assert [:"primary@127.0.0.1", :"node_a@127.0.0.1"] = :rpc.block_call(node_b, Node, :list, [])
  end

  test "Run Commands in a single node" do
    # - Start NodeA
    {:ok, node_a} = Integration.Cluster.spawn(:node_a)

    uuid = UUID.uuid4()

    # - Run Command Start
    assert :ok =
             rpc(node_a, Integration.App, :dispatch, [
               %Integration.Commands.Create{uuid: uuid, message: "create"}
             ])

    # - Inspect State Aggregate
    assert %Integration.Aggregate{message: "create", uuid: uuid} =
             rpc(node_a, Commanded.Aggregates.Aggregate, :aggregate_state, [
               Integration.App,
               Integration.Aggregate,
               uuid
             ])
  end

  test "Run Commands in 2 different Nodes" do
    # - Start Nodes
    {:ok, node_a} = Integration.Cluster.spawn(:node_a)
    {:ok, node_b} = Integration.Cluster.spawn(:node_b)

    uuid = UUID.uuid4()

    # - Run Command Create in NodeA
    assert :ok =
             rpc(node_a, Integration.App, :dispatch, [
               %Integration.Commands.Create{uuid: uuid, message: "create"}
             ])

    # - Run Command Update in NodeB
    assert :ok =
             rpc(node_b, Integration.App, :dispatch, [
               %Integration.Commands.Update{uuid: uuid, message: "update"}
             ])

    # - Inspect State Aggregate in Node A
    assert %Integration.Aggregate{message: "update", uuid: uuid, node: :"node_a@127.0.0.1"} =
             rpc(node_a, Commanded.Aggregates.Aggregate, :aggregate_state, [
               Integration.App,
               Integration.Aggregate,
               uuid
             ])

    # - Inspect State Aggregate in Node B
    assert %Integration.Aggregate{message: "update", uuid: uuid, node: :"node_a@127.0.0.1"} =
             rpc(node_b, Commanded.Aggregates.Aggregate, :aggregate_state, [
               Integration.App,
               Integration.Aggregate,
               uuid
             ])
  end

  test "Check State when a Node is Killed" do
    # - Start Nodes
    {:ok, node_a} = Integration.Cluster.spawn(:node_a)
    {:ok, node_b} = Integration.Cluster.spawn(:node_b)

    uuid = UUID.uuid4()

    # - Run Command Start in NodeA
    assert :ok =
             rpc(node_a, Integration.App, :dispatch, [
               %Integration.Commands.Create{uuid: uuid, message: "create"}
             ])

    # - Kill NodeA
    Integration.Cluster.stop(node_a)

    # - Run Command Update in NodeB
    assert :ok =
             rpc(node_b, Integration.App, :dispatch, [
               %Integration.Commands.Update{uuid: uuid, message: "update"}
             ])

    # - Inspect State Aggregate in Node B
    assert %Integration.Aggregate{message: "update", uuid: uuid, node: :"node_b@127.0.0.1"} =
             rpc(node_b, Commanded.Aggregates.Aggregate, :aggregate_state, [
               Integration.App,
               Integration.Aggregate,
               uuid
             ])
  end

  test "When a node is killed but join again later" do
    # - Start Nodes
    {:ok, node_a} = Integration.Cluster.spawn(:node_a)
    {:ok, node_b} = Integration.Cluster.spawn(:node_b)

    uuid = UUID.uuid4()

    # - Run Command Start in NodeA
    assert :ok =
             rpc(node_a, Integration.App, :dispatch, [
               %Integration.Commands.Create{uuid: uuid, message: "create"}
             ])

    # - Kill NodeA
    Integration.Cluster.stop(node_a)

    # - Run Command Update in NodeB
    assert :ok =
             rpc(node_b, Integration.App, :dispatch, [
               %Integration.Commands.Update{uuid: uuid, message: "update"}
             ])

    # - Start Node A
    {:ok, node_a} = Integration.Cluster.spawn(:node_a)

    # - Run Command Delete in NodeA
    assert :ok =
             rpc(node_a, Integration.App, :dispatch, [
               %Integration.Commands.Delete{uuid: uuid, message: "delete"}
             ])

    # - Inspect State Aggregate in Node B
    assert %Integration.Aggregate{message: "delete", uuid: uuid, node: :"node_b@127.0.0.1"} =
             rpc(node_b, Commanded.Aggregates.Aggregate, :aggregate_state, [
               Integration.App,
               Integration.Aggregate,
               uuid
             ])

    # - Inspect State Aggregate in Node A
    assert %Integration.Aggregate{message: "delete", uuid: uuid, node: :"node_b@127.0.0.1"} =
             rpc(node_a, Commanded.Aggregates.Aggregate, :aggregate_state, [
               Integration.App,
               Integration.Aggregate,
               uuid
             ])
  end

  test "Run Commands in 3 different Nodes - Regression Test" do
    # - Start Nodes
    {:ok, _node_a} = Integration.Cluster.spawn(:node_a)
    {:ok, _node_b} = Integration.Cluster.spawn(:node_b)
    {:ok, node_c} = Integration.Cluster.spawn(:node_c)

    uuid = UUID.uuid4()

    # - Run Command Create in NodeC

    assert :ok =
             rpc(node_c, Integration.App, :dispatch, [
               %Integration.Commands.Create{uuid: uuid, message: "create"}
             ])

    assert :ok =
             rpc(node_c, Integration.App, :dispatch, [
               %Integration.Commands.Update{uuid: uuid, message: "update"}
             ])

    assert :ok =
             rpc(node_c, Integration.App, :dispatch, [
               %Integration.Commands.Delete{uuid: uuid, message: "delete"}
             ])
  end
end
