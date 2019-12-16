defmodule Integration.Events.Created do
  @derive Jason.Encoder

  defstruct [:uuid, :message]
end
