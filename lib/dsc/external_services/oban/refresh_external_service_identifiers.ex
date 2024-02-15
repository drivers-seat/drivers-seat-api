defmodule DriversSeatCoop.ExternalServices.Oban.RefreshExternalServiceIdentifiers do
  @moduledoc """
  This job will update external system identifiers
  """

  use Oban.Worker,
    queue: :sync,
    unique: [
      period: :infinity,
      states: [:available, :scheduled],
      keys: [:service]
    ],
    max_attempts: 3

  require Logger

  alias DriversSeatCoop.ExternalServices

  def schedule_job(service) do
    job =
      new(%{
        service: service
      })

    Oban.insert(job)
    :ok
  end

  @impl Oban.Worker
  def perform(%Oban.Job{
        id: id,
        args: %{
          "service" => service
        }
      }) do
    Logger.metadata(oban_job_id: id)

    Logger.info("Updating #{service} identifiers")

    ExternalServices.update_external_identifiers(service)
    :ok
  end

  @impl Oban.Worker
  def timeout(_job), do: :timer.minutes(10)
end
