defmodule DriversSeatCoop.Earnings.Oban.TriggerUpdateTimespansForOnShiftUsers do
  @moduledoc """
  This job will recalculate work timespans and allocations for users with open shifts
  """

  use Oban.Worker,
    queue: :update_timespans_for_user,
    max_attempts: 3

  require Logger
  alias DriversSeatCoop.Accounts.User
  alias DriversSeatCoop.Earnings.Oban.UpdateTimeSpansForUserWorkday
  alias DriversSeatCoop.Goals.Oban.CalculatePerformanceForUserWindow
  alias DriversSeatCoop.Shifts

  @impl Oban.Worker
  def perform(%Oban.Job{id: id}) do
    Logger.metadata(oban_job_id: id)
    Logger.info("Triggering Periodic timespan calcs for users with open shifts")

    now = DateTime.utc_now()
    users = Shifts.get_users_with_open_shifts()

    users
    |> Enum.each(fn u ->
      working_day = User.datetime_to_working_day(now, u)

      UpdateTimeSpansForUserWorkday.schedule_jobs_for_date_range(
        u.id,
        Date.add(working_day, -2),
        working_day,
        0
      )

      CalculatePerformanceForUserWindow.schedule_jobs_for_date_range(
        u.id,
        Date.add(working_day, -2),
        working_day
      )
    end)

    {:ok, Enum.map(users, fn u -> u.id end)}
  end

  @impl Oban.Worker
  def timeout(_job), do: :timer.minutes(5)
end
