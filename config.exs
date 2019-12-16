use Mix.Config

config :integration, event_stores: [Integration.EventStore]

config :integration, Integration.EventStore,
  registry: :distributed,
  serializer: Commanded.Serialization.JsonSerializer,
  username: "postgres",
  password: "postgres",
  database: "eventstore_dev",
  hostname: "localhost",
  pool_size: 10

config :integration,
  children:
    (Mix.env() == :test && []) ||
      [
        Integration.App,
        {Integration.DistributedSupervisor, name: Integration.DistributedSupervisor},
        {Integration.NodeListener,
         invoke: {Integration.DistributedSupervisor, :start_handlers, []}}
      ]
