import Config

# Database configuration
database_url = System.get_env("DATABASE_URL")

# In development, you can use a non-local database (like Heroku)
# by setting the environment variable
if is_nil(database_url) do
  config :dsc, DriversSeatCoop.Repo,
    username: "postgres",
    password: "postgres",
    database: "drivers_seat_coop_dev",
    hostname: "localhost",
    pool_size: 10,
    show_sensitive_data_on_connection_error: true,
    stacktrace: true,
    types: DriversSeatCoop.PostgresTypes
else
  config :dsc, DriversSeatCoop.Repo,
    ssl: true,
    url: database_url,
    pool_size: 10,
    show_sensitive_data_on_connection_error: true,
    stacktrace: true,
    types: DriversSeatCoop.PostgresTypes
end

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with esbuild to bundle .js and .css sources.
config :dsc, DriversSeatCoopWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  url: [host: "localhost", port: 4000, scheme: "http"],
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "t/MQA0OIkInaNVz/F8s340Jslz7dB+afbIhJcioStg5CjBbhB4W1kaVMJdJU3onC",
  watchers: [
    # Start the esbuild watcher by calling Esbuild.install_and_run(:default, args)
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]}
  ]

config :dsc, DriversSeatCoop.Argyle,
  client_id: System.get_env("ARGYLE_ID"),
  client_secret: System.get_env("ARGYLE_SECRET"),
  enable_background_tasks?: false,
  url: "https://api.argyle.com/v1/"

config :dsc, DriversSeatCoopWeb.Mailer,
  adapter: Swoosh.Adapters.Local,
  from_name: "DriversSeatCoop",
  from_address: "support+dev@example.com"

config :dsc,
  one_signal_api_key: System.get_env("ONE_SIGNAL_API_KEY"),
  one_signal_app_id: System.get_env("ONE_SIGNAL_APP_ID")

config :dsc, DriversSeatCoop.Mixpanel,
  service_account_id: System.get_env("MIX_PANEL_ACCT_ID"),
  service_account_secret: System.get_env("MIX_PANEL_ACCT_SECRET"),
  project_id: System.get_env("MIX_PANEL_PROJECT_ID"),
  project_token: System.get_env("MIX_PANEL_PROJECT_TOKEN")

config :dsc, DriversSeatCoop.B2,
  key_id: System.get_env("B2_KEY_ID"),
  application_key: System.get_env("B2_APPLICATION_KEY"),
  bucket: System.get_env("B2_BUCKET")

config :dsc, DriversSeatCoop.Help, forward_to_csv: System.get_env("HELP_REQUEST_EMAIL_CSV")

# ## SSL Support
#
# In order to use HTTPS in development, a self-signed
# certificate can be generated by running the following
# Mix task:
#
#     mix phx.gen.cert
#
# Note that this task requires Erlang/OTP 20 or later.
# Run `mix help phx.gen.cert` for more information.
#
# The `http:` config above can be replaced with:
#
#     https: [
#       port: 4001,
#       cipher_suite: :strong,
#       keyfile: "priv/cert/selfsigned_key.pem",
#       certfile: "priv/cert/selfsigned.pem"
#     ],
#
# If desired, both `http:` and `https:` keys can be
# configured to run both http and https servers on
# different ports.

# Watch static and templates for browser reloading.
config :dsc, DriversSeatCoopWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/dsc_web/(live|views)/.*(ex)$",
      ~r"lib/dsc_web/templates/.*(eex)$"
    ]
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n", level: :debug

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false
