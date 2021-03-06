defmodule Integration.App do
  @moduledoc false

  use Commanded.Application,
    otp_app: :horde_registry_commanded,
    registry: HordeRegistryCommanded.HordeRegistry,
    event_store: [
      adapter: Commanded.EventStore.Adapters.EventStore,
      event_store: Integration.EventStore
    ]

  router(Integration.Router)
end
