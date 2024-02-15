defmodule DriversSeatCoop.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repositories
      DriversSeatCoop.Repo,
      # Start the Telemetry supervisor
      DriversSeatCoopWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: DriversSeatCoop.PubSub},
      # Start the Endpoint (http/https)
      DriversSeatCoopWeb.Endpoint,
      {Oban, oban_config()}
    ]

    :ok = Oban.Telemetry.attach_default_logger()

    {:ok, _} = Logger.add_backend(Sentry.LoggerBackend)

    :telemetry.attach(
      "oban-errors",
      [:oban, :job, :exception],
      &ObanErrorReporter.handle_event/4,
      []
    )

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DriversSeatCoop.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DriversSeatCoopWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp oban_config do
    env_queues = System.get_env("OBAN_QUEUES")

    :dsc
    |> Application.get_env(Oban)
    |> Keyword.update(:queues, [], &queues(env_queues, &1))
  end

  # OBAN_QUEUES="*" runs all default queues
  defp queues("*", defaults), do: defaults

  # OBAN_QUEUES="" runs no queues
  defp queues(nil, _defaults), do: false

  # disabling default queues runs no queues
  defp queues(_, false), do: false

  # split up list of queues like OBAN_QUEUES="csv_export:3 argyle_api:2"
  defp queues(values, _defaults) when is_binary(values) do
    values
    |> String.split(" ", trim: true)
    |> Enum.map(&String.split(&1, ":", trim: true))
    |> Keyword.new(fn [queue, limit] ->
      {String.to_existing_atom(queue), String.to_integer(limit)}
    end)
  end
end
