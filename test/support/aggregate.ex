defmodule Integration.Aggregate do
  defstruct [:uuid, :message, :node]

  alias Integration.Commands.{Create, Update, Delete}
  alias Integration.Events.{Created, Updated, Deleted}

  def execute(%__MODULE__{}, %Create{uuid: uuid, message: message}) do
    %Created{uuid: uuid, message: message}
  end

  def execute(%__MODULE__{}, %Update{uuid: uuid, message: message}) do
    %Updated{uuid: uuid, message: message}
  end

  def execute(%__MODULE__{}, %Delete{uuid: uuid, message: message}) do
    %Deleted{uuid: uuid, message: message}
  end

  def apply(%__MODULE__{} = state, %{uuid: uuid, message: message}) do
    %__MODULE__{state | uuid: uuid, message: message, node: Node.self()}
  end
end
