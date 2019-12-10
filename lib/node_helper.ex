defmodule NodeHelper do
  use GenServer

  @executable Path.expand("./_build/dev/rel/integration/bin/integration")

  @to_term "|> :erlang.term_to_binary |> IO.inspect"

  ##
  # Client
  ##

  def start(default) do
    GenServer.start_link(__MODULE__, default)
  end

  def rpc(pid, cmd, raw: true) do
    GenServer.call(pid, {:rpc, cmd})
  end

  def rpc(pid, cmd) do
    {output, exit_code} = GenServer.call(pid, {:rpc, cmd <> @to_term})

    {from_term(output), exit_code}
  end

  def connect(node1, node2) do
    {node_address, _} = rpc(node2, "Node.self")

    rpc(node1, "Node.connect(#{inspect(node_address)})")
  end

  def stop(node_name) do
    rpc(node_name, "System.halt()", raw: true)
  end

  ##
  # Server
  ##

  @impl true
  def init(node_name) do
    {:ok, node_name, {:continue, :initialize}}
  end

  @impl true
  def handle_continue(:initialize, node_name) do
    start_node(node_name)
    Process.sleep(100)

    {:noreply, node_name}
  end

  @impl true
  def handle_call({:rpc, cmd}, _from, node_name) do
    result = rpc_node(node_name, cmd)

    {:reply, result, node_name}
  end

  ##
  # Execution
  ##

  defp start_node(name) do
    System.cmd(@executable, ["daemon"], env: [{"NODE_NAME", name}])
  end

  defp rpc_node(node_name, cmd) do
    System.cmd(@executable, ["rpc", cmd], env: [{"NODE_NAME", node_name}])
  end

  defp from_term(text) when is_binary(text) do
    text
    |> String.trim()
    |> Code.eval_string()
    |> elem(0)
    |> :erlang.binary_to_term()
  end
end
