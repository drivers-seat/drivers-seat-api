defmodule DriversSeatCoopWeb.Endpoint do
  use Sentry.PlugCapture
  use Phoenix.Endpoint, otp_app: :dsc

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :dsc,
    gzip: false,
    headers: %{"Access-Control-Allow-Origin" => "*"}

  # Serve at "/web/campaigns" the static files from "priv/static/campaigns" directory.
  plug Plug.Static,
    at: "/web/campaigns",
    from: {:dsc, "priv/static/campaigns"},
    gzip: true,
    headers: %{"Access-Control-Allow-Origin" => "*"}

  # Serve at "/web/help" the static files from "priv/static/help" directory.
  plug Plug.Static,
    at: "/web/help",
    from: {:dsc, "priv/static/help"},
    gzip: true,
    headers: %{"Access-Control-Allow-Origin" => "*"}

  plug Plug.Static,
    at: "/torch",
    from: {:torch, "priv/static"},
    gzip: true,
    cache_control_for_etags: "public, max-age=86400"

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :dsc
  end

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Sentry.PlugContext

  plug Plug.MethodOverride
  plug Plug.Head

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  plug Plug.Session,
    store: :cookie,
    key: "_drivers_seat_coop_key",
    signing_salt: "+qJGcIxw"

  plug Corsica,
    origins: "*",
    allow_methods: :all,
    allow_credentials: true,
    allow_headers: :all,
    expose_headers: ~w(Authorization),
    # Cache cors for a day
    max_age: 60 * 60 * 24,
    log: [rejected: :error, invalid: :error, accepted: :debug]

  plug DriversSeatCoopWeb.Router
end
