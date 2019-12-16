defmodule Integration.EventHandler do
  use Commanded.Event.Handler,
    application: Integration.App,
    name: __MODULE__

  defstruct [:uuid, :message]

  def init do
    with {:ok, _pid} <-
           Agent.start_link(
             fn -> %__MODULE__{uuid: nil, message: nil} end,
             name: __MODULE__
           ) do
      :ok
    end
  end

  def handle(%{uuid: uuid, message: message}, _metadata) do
    Agent.update(__MODULE__, fn state ->
      %__MODULE__{state | uuid: uuid, message: message}
    end)
  end

  def state do
    Agent.get(__MODULE__, fn state -> state end)
  end

  def where_am_i do
    Agent.get(__MODULE__, fn _ -> Node.self() end)
  end
end
