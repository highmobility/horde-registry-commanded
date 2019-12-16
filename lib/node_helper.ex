defmodule NodeHelper do
  use GenServer

  @parser_text "PARSE_ME"
  @executable Path.expand("./_build/dev/rel/integration/bin/integration")

  @to_term "|> IO.inspect() |> :erlang.term_to_binary |> IO.inspect(limit: :infinity, width: :infinity, label: \"#{
             @parser_text
           }\")"

  ##
  # Client
  ##

  def start(default) do
    result = GenServer.start_link(__MODULE__, default)

    # TODO: Use notification instead
    Process.sleep(1000)
    result
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

  defp from_term(""), do: ""
  defp from_term(text) when is_binary(text) do
    try do
      text
      |> filter()
      |> Code.eval_string()
      |> elem(0)
      |> :erlang.binary_to_term()
    rescue
      e ->
        require IEx
        IEx.pry()
        e
    end
  end

  defp filter(text) do
    parser_text = "#{@parser_text}: "
    default = [inspect(:erlang.term_to_binary(nil))]

    text
    |> String.split("\n")
    |> Enum.filter(&String.starts_with?(&1, parser_text))
    |> (fn arg -> arg ++ default end).()
    |> List.first()
    |> String.trim(parser_text)
  end
end
