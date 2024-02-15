defmodule DriversSeatCoop.Earnings.Oban.UpdateTimeSpansForUser do
  @moduledoc """
  This job will recalculate work timespans and allocations for a work date
  """

  use Oban.Worker,
    queue: :update_timespans_for_user,
    unique: [
      period: :infinity,
      states: [:available, :scheduled],
      keys: [:user_id]
    ],
    max_attempts: 3

  require Logger
  alias DriversSeatCoop.Accounts
  alias DriversSeatCoop.Activities
  alias DriversSeatCoop.Earnings
  alias DriversSeatCoop.Earnings.Oban.UpdateTimeSpansForUserWorkday
  alias DriversSeatCoop.Shifts

  @doc """
  Schedule jobs for every user in the system
  """
  def schedule_job do
    Accounts.list_user_ids()
    |> Enum.each(fn uid -> schedule_job(uid) end)
  end

  @doc """
  Schedule the job for a specifi user
  """
  def schedule_job(user_id_or_ids) do
    user_id_or_ids = List.wrap(user_id_or_ids)

    Enum.each(user_id_or_ids, fn user_id ->
      new(%{user_id: user_id})
      |> Oban.insert()
    end)
  end

  @impl Oban.Worker
  def perform(%Oban.Job{
        id: id,
        args: %{"user_id" => user_id}
      }) do
    Logger.metadata(oban_job_id: id)
    Logger.info("Identifying work date range for for user #{user_id}")

    user = Accounts.get_user!(user_id)

    [shift_start_date, shift_end_date] = Shifts.get_shift_date_range(user)

    times =
      if is_nil(shift_start_date) do
        []
      else
        [
          shift_start_date,
          shift_end_date
        ]
      end

    [job_start_date, job_end_date] = Activities.get_activity_date_range(user_id)

    times =
      if is_nil(job_start_date) do
        times
      else
        times
        |> List.insert_at(-1, job_start_date)
        |> List.insert_at(-1, job_end_date)
      end

    [ts_start_date, ts_end_date] = Earnings.get_timespan_date_range(user_id)

    times =
      if is_nil(ts_start_date) do
        times
      else
        times
        |> List.insert_at(-1, ts_start_date)
        |> List.insert_at(-1, ts_end_date)
      end

    if Enum.any?(times) do
      min_time = Enum.max([~D[2015-01-01], Enum.min(times, Date)], Date)
      max_time = Enum.max(times, Date)

      UpdateTimeSpansForUserWorkday.schedule_jobs_for_date_range(
        user_id,
        min_time,
        max_time,
        nil
      )
    else
      :ok
    end
  end

  @impl Oban.Worker
  def timeout(_job), do: :timer.minutes(5)
end
