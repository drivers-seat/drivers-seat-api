defmodule DriversSeatCoop.SendEndShiftReminderTest do
  use DriversSeatCoop.DataCase
  use Oban.Testing, repo: DriversSeatCoop.Repo

  alias DriversSeatCoop.ScheduledShifts.Oban.SendEndShiftReminder
  alias DriversSeatCoop.Shifts

  describe "SendEndShiftReminder job" do
    test "does not fail in normal case" do
      user = Factory.create_user(%{remind_shift_end: true})

      # create an active shift that started 10 minutes ago
      Shifts.create_shift(
        %{start_time: DateTime.utc_now() |> DateTime.add(-10 * 60, :second)},
        user.id,
        nil
      )

      assert :ok =
               perform_job(SendEndShiftReminder, %{
                 user_id: user.id,
                 shift_end_time_local: DateTime.utc_now()
               })
    end

    test "does not fail when user is not currently on shift" do
      user = Factory.create_user(%{remind_shift_end: true})

      assert :ok =
               perform_job(SendEndShiftReminder, %{
                 user_id: user.id,
                 shift_end_time_local: DateTime.utc_now()
               })
    end

    test "does not fail when user cannot receive notifications" do
      user = Factory.create_user(%{remind_shift_end: false})

      # create an active shift that started 10 minutes ago
      Shifts.create_shift(
        %{start_time: DateTime.utc_now() |> DateTime.add(-10 * 60, :second)},
        user.id,
        nil
      )

      assert :ok =
               perform_job(SendEndShiftReminder, %{
                 user_id: user.id,
                 shift_end_time_local: DateTime.utc_now()
               })
    end
  end
end
