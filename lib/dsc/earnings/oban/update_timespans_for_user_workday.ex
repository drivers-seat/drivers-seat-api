defmodule DriversSeatCoop.Earnings.Oban.UpdateTimeSpansForUserWorkday do
  @moduledoc """
  This job will recalculate work timespans and allocations for a work date
  """

  use Oban.Worker,
    queue: :update_timespans_for_user_workday,
    unique: [
      period: :infinity,
      states: [:available, :scheduled, :executing],
      keys: [:user_id, :work_date]
    ],
    max_attempts: 3

  require Logger
  alias DriversSeatCoop.Accounts
  alias DriversSeatCoop.Accounts.User
  alias DriversSeatCoop.Earnings
  alias DriversSeatCoop.Util.DateTimeUtil

  def schedule_job(user_id, work_date_or_dates, delay_seconds) do
    List.wrap(work_date_or_dates)
    |> Enum.uniq()
    |> Enum.filter(fn work_date -> not is_nil(work_date) end)
    |> Enum.each(fn work_date ->
      job =
        if is_nil(delay_seconds) do
          new(%{user_id: user_id, work_date: work_date})
        else
          scheduled_at =
            DateTime.utc_now()
            |> DateTime.add(delay_seconds, :second)

          new(%{user_id: user_id, work_date: work_date},
            scheduled_at: scheduled_at,
            replace: [:scheduled_at]
          )
        end

      Oban.insert(job)
    end)

    :ok
  end

  def schedule_jobs_for_date_range(
        user_id,
        %DateTime{} = start_date,
        %DateTime{} = end_date,
        delay_seconds
      ) do
    user = Accounts.get_user!(user_id)

    working_date_start = DateTimeUtil.datetime_to_working_day(start_date, User.timezone(user))
    working_date_end = DateTimeUtil.datetime_to_working_day(end_date, User.timezone(user))

    schedule_jobs_for_date_range(user_id, working_date_start, working_date_end, delay_seconds)
  end

  def schedule_jobs_for_date_range(
        user_id,
        %Date{} = start_date,
        %Date{} = end_date,
        delay_seconds
      ) do
    # add extra day to end just in case a job cross over the day boundary
    end_date = Date.add(end_date, 1)

    Date.range(start_date, end_date)
    |> Enum.each(fn work_date ->
      schedule_job(user_id, work_date, delay_seconds)
    end)

    :ok
  end

  def schedule_jobs_for_date_range(user_id, start_date, end_date, delay_seconds) do
    {:ok, start_date, _} = DateTime.from_iso8601(start_date)
    {:ok, end_date, _} = DateTime.from_iso8601(end_date)

    schedule_jobs_for_date_range(user_id, start_date, end_date, delay_seconds)
  end

  @impl Oban.Worker
  def perform(%Oban.Job{
        id: id,
        args: %{"user_id" => user_id, "work_date" => work_date}
      }) do
    {:ok, work_date} = Date.from_iso8601(work_date)
    user = Accounts.get_user!(user_id)

    Logger.metadata(oban_job_id: id)
    Logger.info("Calculating timespans and allocations for user #{user_id} on #{work_date}")

    case Earnings.update_timespans_and_allocations_for_user_workday(user, work_date) do
      {:ok, _} -> :ok
      {:error, changeset} -> {:error, changeset}
    end
  end

  @impl Oban.Worker
  def timeout(_job), do: :timer.minutes(5)
end
