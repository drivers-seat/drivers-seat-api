defmodule DriversSeatCoop.Goals.Oban.CalculatePerformanceForUserWindow do
  @moduledoc """
  This job will calculate a users goal performance for a time window.
  """

  use Oban.Worker,
    queue: :goals,
    unique: [
      period: :infinity,
      states: [:available, :scheduled],
      keys: [:user_id, :type, :frequency, :start_date]
    ],
    max_attempts: 3

  require Logger

  alias DriversSeatCoop.Accounts
  alias DriversSeatCoop.Accounts.User
  alias DriversSeatCoop.Goals
  alias DriversSeatCoop.Util.DateTimeUtil

  @frequencies [:day, :week, :month]
  @goal_types [:earnings]

  def schedule_jobs_for_date_range(user_id, %DateTime{} = start_date, %DateTime{} = end_date) do
    user = Accounts.get_user!(user_id)

    working_date_start = DateTimeUtil.datetime_to_working_day(start_date, User.timezone(user))
    working_date_end = DateTimeUtil.datetime_to_working_day(end_date, User.timezone(user))

    schedule_jobs_for_date_range(user_id, working_date_start, working_date_end)
    :ok
  end

  def schedule_jobs_for_date_range(user_id, %Date{} = start_date, %Date{} = end_date) do
    # add extra day to end just in case a job cross over the day boundary
    end_date = Date.add(end_date, 1)

    dates =
      Date.range(start_date, end_date)
      |> Enum.map(fn d -> d end)

    schedule_jobs(user_id, dates)
    :ok
  end

  def schedule_jobs_for_date_range(user_id, start_date, end_date) do
    {:ok, start_date, _} = DateTime.from_iso8601(start_date)
    {:ok, end_date, _} = DateTime.from_iso8601(end_date)

    schedule_jobs_for_date_range(user_id, start_date, end_date)
    :ok
  end

  def schedule_jobs(user_id, date_or_dates) do
    dates =
      List.wrap(date_or_dates)
      |> Enum.uniq()

    for type <- @goal_types,
        frequency <- @frequencies do
      dates
      |> Enum.map(fn d -> DateTimeUtil.get_time_window_for_date(d, frequency) end)
      |> Enum.uniq()
      |> Enum.each(fn {window_start, _window_end} ->
        schedule_job(user_id, type, frequency, window_start)
      end)
    end

    :ok
  end

  def schedule_job(user_id, type, frequency, %Date{} = window_start) do
    job =
      new(%{
        user_id: user_id,
        type: type,
        frequency: frequency,
        start_date: window_start
      })

    Oban.insert(job)
    :ok
  end

  @impl Oban.Worker
  def perform(%Oban.Job{
        id: id,
        args: %{
          "user_id" => user_id,
          "type" => type,
          "frequency" => frequency,
          "start_date" => start_date
        }
      }) do
    Logger.metadata(oban_job_id: id)

    Logger.info(
      "Updating #{type} goal performance for user #{user_id} for #{frequency} of #{start_date}"
    )

    start_date = Date.from_iso8601!(start_date)

    Goals.update_goal_performance(user_id, type, frequency, start_date)
  end

  @impl Oban.Worker
  def timeout(_job), do: :timer.minutes(5)
end
