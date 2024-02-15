defmodule DriversSeatCoop.CommunityInsights.Oban.DeleteOutdatedStats do
  @moduledoc """
  This job will be responsible for deleting community insights stats that
  are outside of the query window
  """
  use Oban.Worker,
    queue: :analytics,
    unique: [
      period: :infinity,
      states: [:available, :scheduled, :executing]
    ],
    max_attempts: 2

  require Logger

  alias DriversSeatCoop.CommunityInsights

  def schedule_job do
    new(%{})
    |> Oban.insert()
  end

  @impl Oban.Worker
  def perform(%Oban.Job{id: id}) do
    Logger.metadata(oban_job_id: id)

    Logger.info("Delete outdated Community Insights Stats")
    CommunityInsights.delete_outdated_stats()
  end

  @impl Oban.Worker
  def timeout(_job), do: :timer.minutes(5)
end
