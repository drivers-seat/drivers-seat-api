defmodule DriversSeatCoop.CommunityInsights.Oban.UpdateCommunityInsightsPayStats do
  @moduledoc """
  This job will be responsible for updating community insights average hourly pay stats
  """
  use Oban.Worker,
    queue: :analytics,
    unique: [
      period: :infinity,
      states: [:available, :scheduled, :executing],
      keys: [:metro_area_id, :week_start_date]
    ],
    max_attempts: 2

  require Logger

  alias DriversSeatCoop.CommunityInsights

  @count_subsets 7

  @doc """
  Run stats update for all metro areas every day for the current week.
  For other weeks, divide group into
  """
  def schedule_job do
    weeks = CommunityInsights.get_weeks_in_scope()

    current_week = Enum.at(weeks, 0)
    other_weeks = Enum.drop(weeks, 1)

    {day_id, _} =
      Date.utc_today()
      |> Date.day_of_era()

    subset_id = rem(day_id, @count_subsets)

    all_metro_area_ids =
      CommunityInsights.get_metro_areas_in_scope()
      |> Enum.sort()

    group_size = ceil(Enum.count(all_metro_area_ids) / @count_subsets)

    subset_metro_area_ids =
      all_metro_area_ids
      |> Enum.drop(subset_id * group_size)
      |> Enum.take(group_size)

    for metro_area_id <- all_metro_area_ids do
      schedule_job(metro_area_id, current_week)
    end

    for week <- other_weeks,
        metro_area_id <- subset_metro_area_ids do
      schedule_job(metro_area_id, week)
    end
  end

  def schedule_job_for_week(week_start_date) do
    week_start_date = CommunityInsights.get_stat_week_start(week_start_date)

    for metro_area_id <- CommunityInsights.get_metro_areas_in_scope() do
      schedule_job(metro_area_id, week_start_date)
    end
  end

  def schedule_job_for_metro(metro_area_id) do
    CommunityInsights.get_weeks_in_scope()
    |> Enum.each(fn week -> schedule_job(metro_area_id, week) end)
  end

  def schedule_job(metro_area_id, %Date{} = week_start_date) do
    new(%{
      metro_area_id: metro_area_id,
      week_start_date: week_start_date
    })
    |> Oban.insert()
  end

  @impl Oban.Worker
  def perform(%Oban.Job{
        id: id,
        args: %{
          "metro_area_id" => metro_area_id,
          "week_start_date" => week_start_date
        }
      }) do
    Logger.metadata(oban_job_id: id)

    Logger.info(
      "Update Community Insights Pay Stats coverage for metro #{metro_area_id}, week #{week_start_date}"
    )

    week_start_date = Date.from_iso8601!(week_start_date)

    CommunityInsights.update_avg_hr_pay_stats_for_metro_week(
      week_start_date,
      metro_area_id
    )
  end

  @impl Oban.Worker
  def perform(%Oban.Job{id: id}) do
    Logger.metadata(oban_job_id: id)

    Logger.info("Update Community Insights Pay Stats coverage")

    schedule_job()
  end

  @impl Oban.Worker
  def timeout(_job), do: :timer.minutes(60)
end
