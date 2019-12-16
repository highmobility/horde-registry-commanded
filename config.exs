use Mix.Config

config :integration, event_stores: [Integration.EventStore]

config :integration, Integration.EventStore,
  serializer: Commanded.Serialization.JsonSerializer,
  username: "postgres",
  password: "postgres",
  database: "eventstore_dev",
  hostname: "localhost",
  pool_size: 10

config :integration,
  children: Mix.env == :test && [] || [
    Integration.App,
    Integration.EventHandler
  ]
