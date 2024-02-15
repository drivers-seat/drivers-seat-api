defmodule DriversSeatCoop.ScheduledShifts.Oban.UpdateScheduledShiftReminders do
  @moduledoc """
  This job will schedule (or reschedule) users' next start and/or end shift reminders.
  """
  use Oban.Worker,
    queue: :shift_reminders,
    max_attempts: 2

  require Logger
  alias DriversSeatCoop.Accounts
  alias DriversSeatCoop.Accounts.User
  alias DriversSeatCoop.ScheduledShifts
  alias DriversSeatCoop.ScheduledShifts.Oban.{SendEndShiftReminder, SendStartShiftReminder}
  alias DriversSeatCoop.Util.DateTimeUtil

  @impl Oban.Worker
  def perform(%Oban.Job{
        id: id
      }) do
    Logger.metadata(oban_job_id: id)

    Logger.info("Updating Scheduled Shift Reminders")

    Accounts.list_users_where_any_shift_reminder_enabled()
    |> Enum.shuffle()
    |> Enum.each(&schedule_reminders_for_user!/1)
  end

  defp schedule_reminders_for_user!(user) do
    timezone = User.timezone(user)
    next_reminder_after_local = DateTime.now!(timezone)

    # Get the user's scheduled shifts
    user_scheduled_shifts = ScheduledShifts.list_scheduled_shifts_by_user_id(user.id)

    {:ok, _} =
      schedule_next_start_reminder(
        user.id,
        user_scheduled_shifts,
        next_reminder_after_local,
        User.can_receive_start_shift_notification(user)
      )

    {:ok, _} =
      schedule_next_end_reminder(
        user.id,
        user_scheduled_shifts,
        next_reminder_after_local,
        User.can_receive_end_shift_notification(user)
      )
  end

  # avoid scheduling because the user has no scheduled shifts
  defp schedule_next_start_reminder(_, [], _, _) do
    {:ok, :not_scheduled}
  end

  # avoid scheduling because the user cannot receive the notification
  defp schedule_next_start_reminder(_, _, _, false) do
    {:ok, :not_scheduled}
  end

  defp schedule_next_start_reminder(
         user_id,
         scheduled_shifts,
         after_timestamp_local,
         true = _can_receive_reminder
       ) do
    next_start_local =
      scheduled_shifts
      |> Enum.map(fn scheduled_shift ->
        DateTimeUtil.get_next_occurrence_after_date(
          after_timestamp_local,
          scheduled_shift.start_day_of_week,
          scheduled_shift.start_time_local
        )
      end)
      |> Enum.min(Date)

    # set reminder to be 10-minutes before the start of scheduled shift.
    schedule_at_utc =
      next_start_local
      |> DateTime.shift_zone!("Etc/UTC")
      |> DateTime.add(-10 * 60, :second)

    SendStartShiftReminder.schedule_job(user_id, next_start_local, schedule_at_utc)
  end

  # avoid scheduling because the user has no scheduled shifts
  defp schedule_next_end_reminder(_, [], _, _) do
    {:ok, :not_scheduled}
  end

  # avoid scheduling because the user cannot receive the notification
  defp schedule_next_end_reminder(_, _, _, false) do
    {:ok, :not_scheduled}
  end

  defp schedule_next_end_reminder(
         user_id,
         scheduled_shifts,
         after_timestamp_local,
         true = _can_receive_reminder
       ) do
    next_end_local =
      scheduled_shifts
      |> Enum.map(fn scheduled_shift ->
        # include the 10-minutes after the end of scheduled shift at this
        # point.  Otherwise, during the 10-minute padding, the next shift
        # will be selected skipping the intended target.
        shift_end_info_with_padding =
          DateTimeUtil.increment_minutes(
            scheduled_shift.start_day_of_week,
            scheduled_shift.start_time_local,
            scheduled_shift.duration_minutes + 10
          )

        DateTimeUtil.get_next_occurrence_after_date(
          after_timestamp_local,
          shift_end_info_with_padding.day_of_week_number,
          shift_end_info_with_padding.time_of_day
        )
      end)
      |> Enum.min(Date)
      |> DateTime.add(-10 * 60, :second)

    schedule_at_utc =
      next_end_local
      |> DateTime.shift_zone!("Etc/UTC")
      |> DateTime.add(10 * 60, :second)

    SendEndShiftReminder.schedule_job(user_id, next_end_local, schedule_at_utc)
  end

  @impl Oban.Worker
  def timeout(_job), do: :timer.minutes(10)
end
