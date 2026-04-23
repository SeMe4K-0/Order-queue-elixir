# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :order_queue,
  ecto_repos: [OrderQueue.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configure the endpoint
config :order_queue, OrderQueueWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: OrderQueueWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: OrderQueue.PubSub,
  live_view: [signing_salt: "7OCwfXh4"]

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :order_queue, Oban,
  repo: OrderQueue.Repo,
  plugins: [Oban.Plugins.Pruner],
  queues: [courier_reassignment: 10]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
