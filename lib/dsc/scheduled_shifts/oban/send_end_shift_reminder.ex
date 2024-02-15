defmodule DriversSeatCoop.ScheduledShifts.Oban.SendEndShiftReminder do
  @moduledoc """
  This job will send a reminder to the user to end their shift based on their
  scheduled shifts.
  """

  use Oban.Worker,
    queue: :shift_reminders,
    unique: [period: :infinity, states: [:available, :scheduled, :executing], keys: [:user_id]],
    max_attempts: 3

  require Logger
  alias DriversSeatCoop.{Accounts, OneSignal, Shifts}

  def schedule_job(
        user_id,
        shift_end_time_local,
        %DateTime{
          time_zone: "Etc/UTC"
        } = scheduled_at_utc
      ) do
    new(%{user_id: user_id, shift_end_time_local: shift_end_time_local},
      scheduled_at: scheduled_at_utc,
      replace: [:scheduled_at, :args]
    )
    |> Oban.insert()
  end

  @impl Oban.Worker
  def perform(%Oban.Job{
        id: id,
        args: %{"user_id" => user_id, "shift_end_time_local" => shift_end_time_local}
      }) do
    Logger.metadata(oban_job_id: id)

    Logger.info(
      "Processing end shift reminder for #{user_id} for shift ending at #{shift_end_time_local}"
    )

    user = Accounts.get_user!(user_id)
    is_on_shift = Shifts.is_user_currently_on_shift(user.id)
    send_reminder!(user, shift_end_time_local, is_on_shift)
  end

  # Reminder is not needed because is currently NOT on shift
  defp send_reminder!(user, shift_end_time_local, false) do
    Logger.info(
      "End shift reminder skipped (not on shift) for #{user.id} for shift ending at #{shift_end_time_local}"
    )
  end

  # User can receive notification and is currently on-shift
  defp send_reminder!(user, shift_end_time_local, true) do
    OneSignal.send_shift_end_reminder(user, shift_end_time_local)
    |> case do
      {:ok, :not_configured} ->
        Logger.info("End shift reminder skipped (not configured) for user #{user.id}")

      {:ok, :user_cannot_receive_notification} ->
        # NOTE: this message should be extremely rare in production because this
        # job should not be scheduled when a user has disabled or cannot receive
        # notifications. This case would only happen when a user has changed
        # their notification settings or been deleted between the job being
        # scheduled and the job being executed.
        Logger.info("End shift reminder skipped (cannot receive) for user #{user.id}")

      {:ok, _} ->
        Logger.info(
          "End shift reminder sent for user #{user.id} for shift ending at #{shift_end_time_local}"
        )
    end
  end

  @impl Oban.Worker
  def timeout(_job), do: :timer.minutes(2)
end
