defmodule Integration.EventStore do
  @moduledoc false

  use EventStore, otp_app: :horde_registry_commanded
end
