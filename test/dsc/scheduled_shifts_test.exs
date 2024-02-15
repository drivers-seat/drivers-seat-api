defmodule DriversSeatCoop.ScheduledShiftsTest do
  use DriversSeatCoop.DataCase
  use Oban.Testing, repo: DriversSeatCoop.Repo

  alias DriversSeatCoop.Accounts
  alias DriversSeatCoop.ScheduledShifts
  alias DriversSeatCoop.Util.DateTimeUtil

  alias DriversSeatCoop.ScheduledShifts.Oban.{
    SendEndShiftReminder,
    SendStartShiftReminder,
    UpdateScheduledShiftReminders
  }

  # Saturday 4pm - Sunday 4am (12-hours)
  @valid_shift_1 %{
    start_day_of_week: 0,
    start_time_local: ~T[16:00:00],
    duration_minutes: 720
  }

  # Sunday 4pm - 10pm (6-hours)
  @valid_shift_2 %{
    start_day_of_week: 0,
    start_time_local: ~T[16:00:00],
    duration_minutes: 360
  }

  # Monday 8am-4pm
  @valid_shift_3 %{
    start_day_of_week: 1,
    start_time_local: ~T[08:00:00],
    duration_minutes: 480
  }

  # Wednesday 8am-4pm
  @valid_shift_4 %{
    start_day_of_week: 3,
    start_time_local: ~T[08:00:00],
    duration_minutes: 480
  }

  # Invalid Start Day
  @invalid_shift_1 %{
    start_day_of_week: -1,
    start_time_local: ~T[08:00:00],
    duration_minutes: 480
  }

  # Invalid Start Day
  @invalid_shift_2 %{
    start_day_of_week: 8,
    start_time_local: ~T[08:00:00],
    duration_minutes: 480
  }

  # Invalid Duration
  @invalid_shift_3 %{
    start_day_of_week: 1,
    start_time_local: ~T[08:00:00],
    duration_minutes: 0
  }

  # Count Minutes >0 and < 10080
  @invalid_shift_4 %{
    start_day_of_week: 1,
    start_time_local: ~T[08:00:00],
    duration_minutes: 10_080
  }

  # Precision of time to the minute
  @invalid_shift_5 %{
    start_day_of_week: 1,
    start_time_local: ~T[08:00:03],
    duration_minutes: 10_080
  }

  # Precision of time to the minute
  @invalid_shift_6 %{
    start_day_of_week: 1,
    start_time_local: ~T[08:00:00.1232],
    duration_minutes: 10_080
  }

  describe "scheduled_shifts" do
    test "list_scheduled_shifts_by_user_id/1 returns scheduled shifts for only that user" do
      user1 = Factory.create_user()
      user2 = Factory.create_user()

      {:ok, expected_user1_shifts} =
        ScheduledShifts.update_scheduled_shifts(
          [
            @valid_shift_1,
            @valid_shift_2
          ],
          user1.id
        )

      {:ok, expected_user2_shifts} =
        ScheduledShifts.update_scheduled_shifts(
          [
            @valid_shift_3,
            @valid_shift_4
          ],
          user2.id
        )

      actual_user1_shifts = ScheduledShifts.list_scheduled_shifts_by_user_id(user1.id)
      actual_user2_shifts = ScheduledShifts.list_scheduled_shifts_by_user_id(user2.id)

      assert expected_user1_shifts == actual_user1_shifts
      assert expected_user2_shifts == actual_user2_shifts
    end

    test "list_scheduled_shifts_by_user_id/1 returns empty set if no scheduled shifts are available" do
      user = Factory.create_user()
      actual = ScheduledShifts.list_scheduled_shifts_by_user_id(user.id)

      assert actual == []
    end

    test "update_scheduled_shifts/2 with valid data replaces shifts for the user" do
      user = Factory.create_user()

      ScheduledShifts.update_scheduled_shifts(
        [
          @valid_shift_1,
          @valid_shift_2
        ],
        user.id
      )

      {:ok, expected} =
        ScheduledShifts.update_scheduled_shifts(
          [
            @valid_shift_3,
            @valid_shift_4
          ],
          user.id
        )

      actual = ScheduledShifts.list_scheduled_shifts_by_user_id(user.id)

      assert expected == actual
    end

    test "update_scheduled_shifts/2 with empty set deletes shifts for the user" do
      user = Factory.create_user()

      ScheduledShifts.update_scheduled_shifts(
        [
          @valid_shift_1,
          @valid_shift_2
        ],
        user.id
      )

      ScheduledShifts.update_scheduled_shifts([], user.id)

      actual = ScheduledShifts.list_scheduled_shifts_by_user_id(user.id)

      assert actual == []
    end

    test "update_scheduled_shifts/2 with invalid data returns an error changeset" do
      user = Factory.create_user()

      assert {:error, %Ecto.Changeset{}} =
               ScheduledShifts.update_scheduled_shifts([@invalid_shift_1], user.id)

      assert {:error, %Ecto.Changeset{}} =
               ScheduledShifts.update_scheduled_shifts([@invalid_shift_2], user.id)

      assert {:error, %Ecto.Changeset{}} =
               ScheduledShifts.update_scheduled_shifts([@invalid_shift_3], user.id)

      assert {:error, %Ecto.Changeset{}} =
               ScheduledShifts.update_scheduled_shifts([@invalid_shift_4], user.id)

      assert {:error, %Ecto.Changeset{}} =
               ScheduledShifts.update_scheduled_shifts([@invalid_shift_5], user.id)

      assert {:error, %Ecto.Changeset{}} =
               ScheduledShifts.update_scheduled_shifts([@invalid_shift_6], user.id)
    end
  end

  describe "UpdateScheduledShiftReminders job" do
    test "enqueues shift-start reminders for applicable users" do
      for opt_out_push <- [true, false],
          deleted <- [true, false],
          remind_shift_start <- [true, false],
          remind_shift_end <- [true, false] do
        user =
          Factory.create_user(%{
            deleted: deleted,
            remind_shift_start: remind_shift_start,
            remind_shift_end: remind_shift_end,
            opted_out_of_push_notifications: opt_out_push
          })

        ScheduledShifts.update_scheduled_shifts(
          [
            @valid_shift_1,
            @valid_shift_3
          ],
          user.id
        )
      end

      assert :ok = perform_job(UpdateScheduledShiftReminders, %{})

      expected =
        Accounts.list_users()
        |> Enum.filter(fn u ->
          !u.deleted and !u.opted_out_of_push_notifications and
            u.remind_shift_start
        end)
        |> Enum.sort_by(fn u -> u.id end)
        |> Enum.map(fn u ->
          %{args: %{user_id: u.id}}
        end)

      actual =
        all_enqueued(worker: SendStartShiftReminder)
        |> Enum.map(fn j ->
          %{
            args: %{
              user_id: Map.fetch!(j.args, "user_id")
            }
          }
        end)
        |> Enum.sort_by(fn u -> u.args.user_id end)

      assert expected == actual
    end

    test "enqueues shift-end reminders for applicable users" do
      for opt_out_push <- [true, false],
          deleted <- [true, false],
          remind_shift_start <- [true, false],
          remind_shift_end <- [true, false] do
        user =
          Factory.create_user(%{
            deleted: deleted,
            remind_shift_start: remind_shift_start,
            remind_shift_end: remind_shift_end,
            opted_out_of_push_notifications: opt_out_push
          })

        ScheduledShifts.update_scheduled_shifts(
          [
            @valid_shift_1,
            @valid_shift_3
          ],
          user.id
        )
      end

      assert :ok = perform_job(UpdateScheduledShiftReminders, %{})

      expected =
        Accounts.list_users()
        |> Enum.filter(fn u ->
          !u.deleted and !u.opted_out_of_push_notifications and
            u.remind_shift_end
        end)
        |> Enum.sort_by(fn u -> u.id end)
        |> Enum.map(fn u ->
          %{args: %{user_id: u.id}}
        end)

      actual =
        all_enqueued(worker: SendEndShiftReminder)
        |> Enum.map(fn j ->
          %{
            args: %{
              user_id: Map.fetch!(j.args, "user_id")
            }
          }
        end)
        |> Enum.sort_by(fn u -> u.args.user_id end)

      assert expected == actual
    end

    test "overwrites existing start-shift reminder job with changes" do
      timezone = "America/Los_Angeles"

      user =
        Factory.create_user(%{
          remind_shift_start: true,
          remind_shift_end: true,
          timezone: timezone
        })

      ScheduledShifts.update_scheduled_shifts(
        [
          @valid_shift_1
        ],
        user.id
      )

      expected_shift_start_1 =
        DateTimeUtil.get_next_occurrence(
          @valid_shift_1.start_day_of_week,
          @valid_shift_1.start_time_local,
          timezone
        )

      expected_1 = [
        construct_expected_start_reminder_job_for_comparison(user.id, expected_shift_start_1)
      ]

      assert :ok = perform_job(UpdateScheduledShiftReminders, %{})

      actual_1 =
        extract_oban_job_info_for_comparison(all_enqueued(worker: SendStartShiftReminder))

      assert expected_1 == actual_1

      ScheduledShifts.update_scheduled_shifts(
        [
          @valid_shift_3
        ],
        user.id
      )

      expected_shift_start_2 =
        DateTimeUtil.get_next_occurrence(
          @valid_shift_3.start_day_of_week,
          @valid_shift_3.start_time_local,
          timezone
        )

      expected_2 = [
        construct_expected_start_reminder_job_for_comparison(user.id, expected_shift_start_2)
      ]

      assert :ok = perform_job(UpdateScheduledShiftReminders, %{})

      actual_2 =
        extract_oban_job_info_for_comparison(all_enqueued(worker: SendStartShiftReminder))

      assert expected_2 == actual_2
    end

    test "overwrites existing end-shift reminder job with changes" do
      timezone = "America/Los_Angeles"

      user =
        Factory.create_user(%{
          remind_shift_start: true,
          remind_shift_end: true,
          timezone: timezone
        })

      ScheduledShifts.update_scheduled_shifts(
        [
          @valid_shift_1
        ],
        user.id
      )

      expected_shift_end_info_1 =
        DateTimeUtil.increment_minutes(
          @valid_shift_1.start_day_of_week,
          @valid_shift_1.start_time_local,
          @valid_shift_1.duration_minutes
        )

      expected_shift_end_1 =
        DateTimeUtil.get_next_occurrence(
          expected_shift_end_info_1.day_of_week_number,
          expected_shift_end_info_1.time_of_day,
          timezone
        )

      expected_1 = [
        construct_expected_end_reminder_job_for_comparison(user.id, expected_shift_end_1)
      ]

      assert :ok = perform_job(UpdateScheduledShiftReminders, %{})

      actual_1 = extract_oban_job_info_for_comparison(all_enqueued(worker: SendEndShiftReminder))

      assert expected_1 == actual_1

      ScheduledShifts.update_scheduled_shifts(
        [
          @valid_shift_3
        ],
        user.id
      )

      expected_shift_end_info_2 =
        DateTimeUtil.increment_minutes(
          @valid_shift_3.start_day_of_week,
          @valid_shift_3.start_time_local,
          @valid_shift_3.duration_minutes
        )

      expected_shift_start_2 =
        DateTimeUtil.get_next_occurrence(
          expected_shift_end_info_2.day_of_week_number,
          expected_shift_end_info_2.time_of_day,
          timezone
        )

      expected_2 = [
        construct_expected_end_reminder_job_for_comparison(user.id, expected_shift_start_2)
      ]

      assert :ok = perform_job(UpdateScheduledShiftReminders, %{})

      actual_2 = extract_oban_job_info_for_comparison(all_enqueued(worker: SendEndShiftReminder))

      assert expected_2 == actual_2
    end

    test "picks the next possible start-shift reminder time" do
      timezone = "America/Los_Angeles"

      user =
        Factory.create_user(%{
          remind_shift_start: true,
          remind_shift_end: true,
          timezone: timezone
        })

      now_local = DateTime.now!(timezone)
      day_of_week = Date.day_of_week(now_local, :sunday)

      time = DateTime.to_time(now_local)

      time =
        Time.new!(time.hour, time.minute, 0)
        |> Time.add(60 * 60, :second)

      scheduled_shifts =
        for d <- [0, 1, 3, 5] do
          %{
            start_day_of_week: rem(day_of_week + d, 7),
            start_time_local: time,
            duration_minutes: 360
          }
        end

      {:ok, scheduled_shifts} =
        ScheduledShifts.update_scheduled_shifts(
          scheduled_shifts,
          user.id
        )

      next_start_time =
        Enum.map(scheduled_shifts, fn s ->
          DateTimeUtil.get_next_occurrence(s.start_day_of_week, s.start_time_local, timezone)
        end)
        |> Enum.min(Date)

      expected = construct_expected_start_reminder_job_for_comparison(user.id, next_start_time)

      assert :ok = perform_job(UpdateScheduledShiftReminders, %{})

      actual =
        extract_oban_job_info_for_comparison(all_enqueued(worker: SendStartShiftReminder))
        |> Enum.at(0)

      assert expected == actual
      assert DateTime.compare(actual.scheduled_at, now_local) == :gt
    end

    test "picks the next possible end-shift reminder time" do
      timezone = "America/Los_Angeles"

      user =
        Factory.create_user(%{
          remind_shift_start: true,
          remind_shift_end: true,
          timezone: timezone
        })

      now_local = DateTime.now!(timezone)
      day_of_week = Date.day_of_week(now_local, :sunday)

      time = DateTime.to_time(now_local)

      time =
        Time.new!(time.hour, time.minute, 0)
        |> Time.add(-60 * 60, :second)

      scheduled_shifts =
        for d <- [0, 1, 3, 5] do
          %{
            start_day_of_week: rem(day_of_week + d, 7),
            start_time_local: time,
            duration_minutes: 360
          }
        end

      {:ok, scheduled_shifts} =
        ScheduledShifts.update_scheduled_shifts(
          scheduled_shifts,
          user.id
        )

      next_end_time =
        Enum.map(scheduled_shifts, fn s ->
          end_time_info =
            DateTimeUtil.increment_minutes(
              s.start_day_of_week,
              s.start_time_local,
              s.duration_minutes
            )

          DateTimeUtil.get_next_occurrence(
            end_time_info.day_of_week_number,
            end_time_info.time_of_day,
            timezone
          )
        end)
        |> Enum.min(Date)

      expected = construct_expected_end_reminder_job_for_comparison(user.id, next_end_time)

      assert :ok = perform_job(UpdateScheduledShiftReminders, %{})

      actual =
        extract_oban_job_info_for_comparison(all_enqueued(worker: SendEndShiftReminder))
        |> Enum.at(0)

      assert expected == actual
      assert DateTime.compare(actual.scheduled_at, now_local) == :gt
    end

    test "considers the 10-minute grace-period when picking next reminder time" do
      timezone = "America/Los_Angeles"

      user =
        Factory.create_user(%{
          remind_shift_start: true,
          remind_shift_end: true,
          timezone: timezone
        })

      now_local = DateTime.now!(timezone)
      day_of_week = Date.day_of_week(now_local, :sunday)

      time = DateTime.to_time(now_local)

      # establish shifts that ended 2-minutes ago.  Even though the shift has
      # passed, it is still in the grace period before reminder is sent, so it
      # is the one that should be picked.
      # example:  Shift ends 10am, it is not 10:02am...  The next reminder is 10:10am
      # and should be picked.
      time =
        Time.new!(time.hour, time.minute, 0)
        |> Time.add(-62 * 60, :second)

      scheduled_shifts =
        for d <- [0, 1, 3, 5] do
          %{
            start_day_of_week: rem(day_of_week + d, 7),
            start_time_local: time,
            duration_minutes: 60
          }
        end

      {:ok, scheduled_shifts} =
        ScheduledShifts.update_scheduled_shifts(
          scheduled_shifts,
          user.id
        )

      next_end_time =
        Enum.map(scheduled_shifts, fn s ->
          end_time_info =
            DateTimeUtil.increment_minutes(
              s.start_day_of_week,
              s.start_time_local,
              s.duration_minutes + 10
            )

          DateTimeUtil.get_next_occurrence(
            end_time_info.day_of_week_number,
            end_time_info.time_of_day,
            timezone
          )
        end)
        |> Enum.min(Date)
        |> DateTime.add(-10 * 60, :second)

      expected = construct_expected_end_reminder_job_for_comparison(user.id, next_end_time)

      assert :ok = perform_job(UpdateScheduledShiftReminders, %{})

      actual =
        extract_oban_job_info_for_comparison(all_enqueued(worker: SendEndShiftReminder))
        |> Enum.at(0)

      assert expected == actual
      assert DateTime.compare(actual.scheduled_at, now_local) == :gt
    end

    test "does not fail when no shifts are available" do
      timezone = "America/Los_Angeles"

      user =
        Factory.create_user(%{
          remind_shift_start: true,
          remind_shift_end: true,
          timezone: timezone
        })

      ScheduledShifts.update_scheduled_shifts([], user.id)

      assert :ok = perform_job(UpdateScheduledShiftReminders, %{})

      actual = extract_oban_job_info_for_comparison(all_enqueued(worker: SendEndShiftReminder))

      assert [] == actual
    end

    defp extract_oban_job_info_for_comparison(oban_jobs) do
      oban_jobs
      |> Enum.map(fn j ->
        %{
          scheduled_at: DateTime.truncate(j.scheduled_at, :second),
          args: j.args
        }
      end)
    end

    defp construct_expected_start_reminder_job_for_comparison(user_id, start_time) do
      scheduled_at =
        DateTime.shift_zone!(start_time, "Etc/UTC")
        |> DateTime.add(-10 * 60, :second)

      %{
        scheduled_at: DateTime.truncate(scheduled_at, :second),
        args: %{
          "shift_start_time_local" => DateTime.to_iso8601(start_time),
          "user_id" => user_id
        }
      }
    end

    defp construct_expected_end_reminder_job_for_comparison(user_id, end_time) do
      scheduled_at =
        DateTime.shift_zone!(end_time, "Etc/UTC")
        |> DateTime.add(10 * 60, :second)

      %{
        scheduled_at: DateTime.truncate(scheduled_at, :second),
        args: %{
          "shift_end_time_local" => DateTime.to_iso8601(end_time),
          "user_id" => user_id
        }
      }
    end
  end
end
