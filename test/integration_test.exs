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

  test "start and connect 2 nodes" do
    {:ok, node_a} = Integration.Cluster.spawn(:node_a)
    {:ok, node_b} = Integration.Cluster.spawn(:node_b)

    require IEx
    IEx.pry()

    assert [:"primary@127.0.0.1", :"node_b@127.0.0.1"] = :rpc.block_call(node_a, Node, :list, [])
    assert [:"primary@127.0.0.1", :"node_a@127.0.0.1"] = :rpc.block_call(node_b, Node, :list, [])

    Integration.Cluster.stop(node_a)
    Integration.Cluster.stop(node_b)
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

    # - Inspect State EventHandler
    assert %Integration.EventHandler{
             message: "create",
             uuid: uuid
           } = rpc(node_a, Integration.EventHandler, :state, [])

    Integration.Cluster.stop(node_a)
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

    # - Inspect where EventHandler is running
    assert :"node_a@127.0.0.1" = rpc(node_a, Integration.EventHandler, :where_am_i, [])

    # - Inspect State EventHandler in Node A
    assert %Integration.EventHandler{
             message: "update",
             uuid: uuid
           } = rpc(node_a, Integration.EventHandler, :state, [])

    # - Inspect Event Handler Node B
    refute rpc(node_b, Process, :whereis, [Integration.EventHandler])

    Integration.Cluster.stop(node_a)
    Integration.Cluster.stop(node_b)
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

    # - Inspect Event Handler Node B
    assert :"node_b@127.0.0.1" = rpc(node_b, Integration.EventHandler, :where_am_i, [])

    # - Inspect State EventHandler in Node B
    assert %Integration.EventHandler{
             message: "update",
             uuid: uuid
           } = rpc(node_b, Integration.EventHandler, :state, [])

    Integration.Cluster.stop(node_b)
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

    node_a_result =
      rpc(node_a, Process, :whereis, [Integration.EventHandler]) &&
        rpc(node_a, Integration.EventHandler, :state, [])

    node_b_result =
      rpc(node_b, Process, :whereis, [Integration.EventHandler]) &&
        rpc(node_b, Integration.EventHandler, :state, [])

    assert %Integration.EventHandler{message: "delete", uuid: uuid} =
             Enum.find([node_a_result, node_b_result], &is_map/1)

    Integration.Cluster.stop(node_a)
    Integration.Cluster.stop(node_b)
  end
end
