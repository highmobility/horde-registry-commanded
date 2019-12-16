defmodule Integration.DistributedSupervisor do
  @moduledoc false
  use Horde.DynamicSupervisor

  def start_handlers() do
    Horde.DynamicSupervisor.start_child(__MODULE__, %{
      id: :gen_server,
      start: {Integration.EventHandler, :start_link, []}
    })
  end

  def start_link(options) do
    Horde.DynamicSupervisor.start_link(__MODULE__, [], options)
  end

  def init(init_arg) do
    [strategy: :one_for_one, members: Integration.NodeListener.members(__MODULE__)]
    |> Keyword.merge(init_arg)
    |> Horde.DynamicSupervisor.init()
  end
end
