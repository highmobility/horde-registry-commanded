defmodule Integration.Events.Updated do
  @derive Jason.Encoder

  defstruct [:uuid, :message]
end
