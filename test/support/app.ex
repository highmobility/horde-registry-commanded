defmodule Integration.App do
  @moduledoc false

  use Commanded.Application,
    otp_app: :integration,
    registry: Integration.HordeRegistry,
    pubsub: [
      phoenix_pubsub: [
        adapter: Phoenix.PubSub.PG2,
        pool_size: 1
      ]
    ],
    event_store: [
      adapter: Commanded.EventStore.Adapters.EventStore,
      event_store: Integration.EventStore
    ]

  router(Integration.Router)
end
