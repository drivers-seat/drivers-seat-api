defmodule DriversSeatCoop.CommunityInsights.Oban.UpdateMetroAreaCoverageStats do
  @moduledoc """
  This job will be responsible for updating coverage stats for a metro area
  """
  use Oban.Worker,
    queue: :analytics,
    unique: [
      period: :infinity,
      states: [:available, :scheduled, :executing],
      keys: [:metro_area_id]
    ],
    max_attempts: 2

  require Logger

  alias DriversSeatCoop.CommunityInsights
  alias DriversSeatCoop.Regions

  def schedule_job do
    Regions.get_metro_areas()
    |> Enum.each(fn metro_area -> schedule_job(metro_area.id) end)
  end

  def schedule_job(metro_area_id) do
    new(%{
      metro_area_id: metro_area_id
    })
    |> Oban.insert()
  end

  @impl Oban.Worker
  def perform(%Oban.Job{
        id: id,
        args: %{
          "metro_area_id" => metro_area_id
        }
      }) do
    Logger.metadata(oban_job_id: id)

    Logger.info("Update Metro Area Coverage Stats for metro #{metro_area_id}")

    CommunityInsights.update_metro_area_stats(metro_area_id)
  end

  def perform(%Oban.Job{id: id}) do
    Logger.metadata(oban_job_id: id)
    Logger.info("Update Metro Area Coverage Stats for all Metro Areas")
    schedule_job()
  end

  @impl Oban.Worker
  def timeout(_job), do: :timer.minutes(5)
end
