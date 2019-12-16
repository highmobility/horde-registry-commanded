defmodule Integration.Events.Deleted do
  @derive Jason.Encoder

  defstruct [:uuid, :message]
end
