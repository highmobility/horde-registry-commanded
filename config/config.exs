use Mix.Config

config :integration, event_stores: [Integration.EventStore]

config :integration, Integration.EventStore,
  registry: :distributed,
  serializer: Commanded.Serialization.JsonSerializer,
  username: "postgres",
  password: "postgres",
  database: "eventstore_test",
  hostname: "localhost",
  pool_size: 10
