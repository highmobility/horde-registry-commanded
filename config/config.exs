use Mix.Config

config :integration, event_stores: [Integration.EventStore]

config :integration, Integration.EventStore,
  registry: :distributed,
  serializer: Commanded.Serialization.JsonSerializer,
  username: "postgres",
  password: "postgres",
  database: "eventstore_test",
  hostname: "localhost",
  port: String.to_integer(System.get_env("POSTGRES_PORT", "5432")),
  pool_size: 10
