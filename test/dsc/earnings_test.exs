defmodule DriversSeatCoop.EarningsTest do
  use DriversSeatCoop.DataCase

  alias DriversSeatCoop.Accounts.User
  alias DriversSeatCoop.Earnings
  alias DriversSeatCoop.Factory
  alias DriversSeatCoop.Irs
  alias DriversSeatCoop.Shifts
  alias DriversSeatCoop.Util.DateTimeUtil

  describe "calculate timespans - user facing" do
    test "Buckets into the proper local workday - shift" do
      user =
        Factory.create_user(%{
          timezone: "America/Los_Angeles"
        })

      # Shift: 11:15am - 3:39am
      shift_start_time = get_utc_date(~N[2023-03-13T23:15:00Z], user.timezone)
      shift_end_time = get_utc_date(~N[2023-03-14T03:39:00Z], user.timezone)

      shift =
        Factory.create_shift(%{
          user_id: user.id,
          start_time: shift_start_time,
          end_time: shift_end_time
        })

      timespans_0312 =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-12],
          "user_facing"
        )

      timespans_0313 =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-13],
          "user_facing"
        )

      timespans_0314 =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-14],
          "user_facing"
        )

      assert Enum.count(timespans_0313) == 1
      timespan_0313 = Enum.at(timespans_0313, 0)
      assert DateTime.compare(shift_start_time, timespan_0313.start_time) == :eq
      assert DateTime.compare(shift_end_time, timespan_0313.end_time) == :eq
      assert DateTime.compare(shift_end_time, timespan_0313.end_time) == :eq
      assert timespan_0313.shift_ids == [shift.id]

      assert Enum.count(timespan_0313.allocations) == 1
      alloc = Enum.at(timespan_0313.allocations, 0)
      assert DateTime.compare(shift_start_time, alloc.start_time) == :eq
      assert DateTime.compare(shift_end_time, alloc.end_time) == :eq
      assert DateTime.diff(shift_end_time, shift_start_time) == alloc.duration_seconds
      assert is_nil(Map.get(alloc, :activity_id))
      assert is_nil(Map.get(alloc, :activity_coverage_percent))

      assert Enum.empty?(timespans_0314)
      assert Enum.empty?(timespans_0312)
    end

    test "Includes open shifts when creating timespans" do
      user =
        Factory.create_user(%{
          timezone: "America/Los_Angeles"
        })

      # Shift: 11:15am+
      shift_start_time = get_utc_date(~N[2023-03-13T23:15:00Z], user.timezone)

      [_day_start_0313, day_end_0313] =
        DateTimeUtil.working_day_bounds(~D[2023-03-13], "America/Los_Angeles")

      [day_start_0314, day_end_0314] =
        DateTimeUtil.working_day_bounds(~D[2023-03-14], "America/Los_Angeles")

      shift =
        Factory.create_shift(%{
          user_id: user.id,
          start_time: shift_start_time
        })

      timespans_0312 =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-12],
          "user_facing"
        )

      timespans_0313 =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-13],
          "user_facing"
        )

      timespans_0314 =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-14],
          "user_facing"
        )

      assert not Enum.any?(timespans_0312)

      assert Enum.count(timespans_0313) == 1
      timespan_0313 = Enum.at(timespans_0313, 0)
      assert DateTime.compare(shift_start_time, timespan_0313.start_time) == :eq
      assert DateTime.compare(day_end_0313, timespan_0313.end_time) == :eq
      assert timespan_0313.shift_ids == [shift.id]

      assert Enum.count(timespans_0314) == 1
      timespan_0314 = Enum.at(timespans_0314, 0)
      assert DateTime.compare(day_start_0314, timespan_0314.start_time) == :eq
      assert DateTime.compare(day_end_0314, timespan_0314.end_time) == :eq
      assert timespan_0314.shift_ids == [shift.id]
    end

    test "Buckets into proper local workday - activity" do
      user =
        Factory.create_user(%{
          timezone: "America/Los_Angeles"
        })

      # Activity: 12:15am - 1:15am
      activity_start_time = get_utc_date(~N[2023-03-14T00:15:00Z], user.timezone)
      activity_end_time = get_utc_date(~N[2023-03-14T01:15:00Z], user.timezone)

      activity =
        Factory.create_activity(user.id, %{
          "timezone" => user.timezone,
          "employer" => "uber",
          "duration" => 1200,
          "distance" => "10.3",
          "earning_type" => "work",
          "status" => "completed",
          "num_tasks" => 3,
          "start_date" => activity_start_time,
          "end_date" => activity_end_time
        })

      timespans_0312 =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-12],
          "user_facing"
        )

      timespans_0313 =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-13],
          "user_facing"
        )

      timespans_0314 =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-14],
          "user_facing"
        )

      assert Enum.count(timespans_0313) == 1
      timespan_0313 = Enum.at(timespans_0313, 0)
      assert DateTime.compare(activity_start_time, timespan_0313.start_time) == :eq
      assert DateTime.compare(activity_end_time, timespan_0313.end_time) == :eq
      assert Map.get(timespan_0313, :shift_ids, []) == []

      assert timespan_0313.duration_seconds ==
               DateTime.diff(timespan_0313.end_time, timespan_0313.start_time)

      assert Enum.count(timespan_0313.allocations) == 1
      alloc = Enum.at(timespan_0313.allocations, 0)
      assert DateTime.compare(activity_start_time, alloc.start_time) == :eq
      assert DateTime.compare(activity_end_time, alloc.end_time) == :eq
      assert DateTime.diff(activity_end_time, activity_start_time) == alloc.duration_seconds
      assert alloc.activity_id == activity.id
      assert alloc.activity_coverage_percent == 1

      assert not Enum.any?(timespans_0314)
      assert not Enum.any?(timespans_0312)
    end

    test "Splits on workday boundary- shift" do
      user =
        Factory.create_user(%{
          timezone: "America/Los_Angeles"
        })

      day_break = get_utc_date(~N[2023-03-14T04:00:00Z], user.timezone)

      # Shift: 11:15am - 3:39am
      shift_start_time = get_utc_date(~N[2023-03-13T23:15:00Z], user.timezone)
      shift_end_time = get_utc_date(~N[2023-03-14T05:39:00Z], user.timezone)

      shift =
        Factory.create_shift(%{
          user_id: user.id,
          start_time: shift_start_time,
          end_time: shift_end_time
        })

      timespans_0312 =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-12],
          "user_facing"
        )

      timespans_0313 =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-13],
          "user_facing"
        )

      timespans_0314 =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-14],
          "user_facing"
        )

      assert Enum.count(timespans_0313) == 1
      timespan_0313 = Enum.at(timespans_0313, 0)
      assert DateTime.compare(shift_start_time, timespan_0313.start_time) == :eq
      assert DateTime.compare(day_break, timespan_0313.end_time) == :eq
      assert timespan_0313.shift_ids == [shift.id]

      assert timespan_0313.duration_seconds ==
               DateTime.diff(timespan_0313.end_time, timespan_0313.start_time)

      assert Enum.count(timespan_0313.allocations) == 1
      alloc = Enum.at(timespan_0313.allocations, 0)
      assert DateTime.compare(shift_start_time, alloc.start_time) == :eq
      assert DateTime.compare(day_break, alloc.end_time) == :eq
      assert DateTime.diff(day_break, shift_start_time) == alloc.duration_seconds
      assert is_nil(Map.get(alloc, :activity_id))
      assert is_nil(Map.get(alloc, :activity_coverage_percent))

      assert Enum.count(timespans_0314) == 1
      timespan_0314 = Enum.at(timespans_0314, 0)
      assert DateTime.compare(day_break, timespan_0314.start_time) == :eq
      assert DateTime.compare(shift_end_time, timespan_0314.end_time) == :eq
      assert timespan_0314.shift_ids == [shift.id]

      assert timespan_0314.duration_seconds ==
               DateTime.diff(timespan_0314.end_time, timespan_0314.start_time)

      assert Enum.count(timespan_0314.allocations) == 1
      alloc = Enum.at(timespan_0314.allocations, 0)
      assert DateTime.compare(day_break, alloc.start_time) == :eq
      assert DateTime.compare(shift_end_time, alloc.end_time) == :eq
      assert DateTime.diff(shift_end_time, day_break) == alloc.duration_seconds
      assert is_nil(Map.get(alloc, :activity_id))
      assert is_nil(Map.get(alloc, :activity_coverage_percent))

      assert Enum.empty?(timespans_0312)
    end

    test "Splits on workday boundary - activity" do
      user =
        Factory.create_user(%{
          timezone: "America/Los_Angeles"
        })

      day_break = get_utc_date(~N[2023-03-14T04:00:00Z], user.timezone)

      # Activity: 12:15am - 1:15am
      activity_start_time = get_utc_date(~N[2023-03-14T00:15:00Z], user.timezone)
      activity_end_time = get_utc_date(~N[2023-03-14T05:15:00Z], user.timezone)

      activity =
        Factory.create_activity(user.id, %{
          "timezone" => user.timezone,
          "employer" => "uber",
          "duration" => 1200,
          "distance" => "10.3",
          "earning_type" => "work",
          "status" => "completed",
          "num_tasks" => 3,
          "start_date" => activity_start_time,
          "end_date" => activity_end_time
        })

      timespans_0312 =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-12],
          "user_facing"
        )

      timespans_0313 =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-13],
          "user_facing"
        )

      timespans_0314 =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-14],
          "user_facing"
        )

      assert Enum.count(timespans_0313) == 1
      timespan_0313 = Enum.at(timespans_0313, 0)
      assert DateTime.compare(activity_start_time, timespan_0313.start_time) == :eq
      assert DateTime.compare(day_break, timespan_0313.end_time) == :eq

      assert Enum.count(timespan_0313.allocations) == 1
      alloc = Enum.at(timespan_0313.allocations, 0)
      assert DateTime.compare(activity_start_time, alloc.start_time) == :eq
      assert DateTime.compare(day_break, alloc.end_time) == :eq
      assert DateTime.diff(day_break, activity_start_time) == alloc.duration_seconds
      assert alloc.activity_id == activity.id
      assert alloc.activity_coverage_percent == 0.75
      assert alloc.activity_extends_before == false
      assert alloc.activity_extends_after == true

      assert Enum.count(timespans_0314) == 1
      timespan_0314 = Enum.at(timespans_0314, 0)
      assert DateTime.compare(day_break, timespan_0314.start_time) == :eq
      assert DateTime.compare(activity_end_time, timespan_0314.end_time) == :eq

      assert Enum.count(timespan_0314.allocations) == 1
      alloc = Enum.at(timespan_0314.allocations, 0)
      assert DateTime.compare(day_break, alloc.start_time) == :eq
      assert DateTime.compare(activity_end_time, alloc.end_time) == :eq
      assert DateTime.diff(activity_end_time, day_break) == alloc.duration_seconds
      assert alloc.activity_id == activity.id
      assert alloc.activity_coverage_percent == 0.25
      assert alloc.activity_extends_before == true
      assert alloc.activity_extends_after == false

      assert Enum.empty?(timespans_0312)
    end

    test "Deals with overlapping shifts and activities - 1" do
      user =
        Factory.create_user(%{
          timezone: "America/Los_Angeles"
        })

      # Shift: 12:15pm - 4:15pm
      shift_start_time = get_utc_date(~N[2023-03-14T12:15:00Z], user.timezone)
      shift_end_time = get_utc_date(~N[2023-03-14T16:15:00Z], user.timezone)

      shift =
        Factory.create_shift(%{
          user_id: user.id,
          start_time: shift_start_time,
          end_time: shift_end_time
        })

      # Activity: 12:30pm - 2:15pm
      activity_start_time = get_utc_date(~N[2023-03-14T12:30:00Z], user.timezone)
      activity_end_time = get_utc_date(~N[2023-03-14T14:15:00Z], user.timezone)

      activity =
        Factory.create_activity(user.id, %{
          "timezone" => user.timezone,
          "employer" => "uber",
          "duration" => 1200,
          "distance" => "10.3",
          "earning_type" => "work",
          "status" => "completed",
          "num_tasks" => 3,
          "start_date" => activity_start_time,
          "end_date" => activity_end_time
        })

      timespans_0313 =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-13],
          "user_facing"
        )

      timespans_0314 =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-14],
          "user_facing"
        )

      timespans_0315 =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-15],
          "user_facing"
        )

      assert Enum.empty?(timespans_0313)

      assert Enum.count(timespans_0314) == 1
      timespan_0314 = Enum.at(timespans_0314, 0)
      assert DateTime.compare(shift_start_time, timespan_0314.start_time) == :eq
      assert DateTime.compare(shift_end_time, timespan_0314.end_time) == :eq
      assert timespan_0314.shift_ids == [shift.id]

      assert Enum.count(timespan_0314.allocations) == 3

      alloc_0 = Enum.at(timespan_0314.allocations, 0)
      assert DateTime.compare(shift_start_time, alloc_0.start_time) == :eq
      assert DateTime.compare(activity_start_time, alloc_0.end_time) == :eq
      assert DateTime.diff(activity_start_time, shift_start_time) == alloc_0.duration_seconds
      assert is_nil(Map.get(alloc_0, :activity_id))
      assert is_nil(Map.get(alloc_0, :activity_coverage_percent))

      alloc_1 = Enum.at(timespan_0314.allocations, 1)
      assert DateTime.compare(activity_start_time, alloc_1.start_time) == :eq
      assert DateTime.compare(activity_end_time, alloc_1.end_time) == :eq
      assert DateTime.diff(activity_end_time, activity_start_time) == alloc_1.duration_seconds
      assert alloc_1.activity_id == activity.id
      assert alloc_1.activity_coverage_percent == 1
      assert alloc_1.activity_extends_before == false
      assert alloc_1.activity_extends_after == false

      alloc_2 = Enum.at(timespan_0314.allocations, 2)
      assert DateTime.compare(activity_end_time, alloc_2.start_time) == :eq
      assert DateTime.compare(shift_end_time, alloc_2.end_time) == :eq
      assert DateTime.diff(shift_end_time, activity_end_time) == alloc_2.duration_seconds
      assert is_nil(Map.get(alloc_2, :activity_id))
      assert is_nil(Map.get(alloc_2, :activity_coverage_percent))

      assert Enum.empty?(timespans_0315)
    end

    test "Deals with overlapping shifts and activities - 2" do
      user =
        Factory.create_user(%{
          timezone: "America/Los_Angeles"
        })

      # Shift: 12:15pm - 3:15pm
      shift_start_time = get_utc_date(~N[2023-03-14T12:15:00Z], user.timezone)
      shift_end_time = get_utc_date(~N[2023-03-14T15:15:00Z], user.timezone)

      shift =
        Factory.create_shift(%{
          user_id: user.id,
          start_time: shift_start_time,
          end_time: shift_end_time
        })

      # Activity: 3:00pm - 4:15pm
      activity_start_time = get_utc_date(~N[2023-03-14T15:00:00Z], user.timezone)
      activity_end_time = get_utc_date(~N[2023-03-14T16:15:00Z], user.timezone)

      activity =
        Factory.create_activity(user.id, %{
          "timezone" => user.timezone,
          "employer" => "uber",
          "duration" => 1200,
          "distance" => "10.3",
          "earning_type" => "work",
          "status" => "completed",
          "num_tasks" => 3,
          "start_date" => activity_start_time,
          "end_date" => activity_end_time
        })

      timespans_0313 =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-13],
          "user_facing"
        )

      timespans_0314 =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-14],
          "user_facing"
        )

      timespans_0315 =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-15],
          "user_facing"
        )

      assert Enum.empty?(timespans_0313)

      assert Enum.count(timespans_0314) == 1
      timespan_0314 = Enum.at(timespans_0314, 0)
      assert DateTime.compare(shift_start_time, timespan_0314.start_time) == :eq
      assert DateTime.compare(activity_end_time, timespan_0314.end_time) == :eq
      assert timespan_0314.shift_ids == [shift.id]

      assert Enum.count(timespan_0314.allocations) == 2

      alloc_0 = Enum.at(timespan_0314.allocations, 0)
      assert DateTime.compare(shift_start_time, alloc_0.start_time) == :eq
      assert DateTime.compare(activity_start_time, alloc_0.end_time) == :eq
      assert DateTime.diff(activity_start_time, shift_start_time) == alloc_0.duration_seconds
      assert is_nil(Map.get(alloc_0, :activity_id))
      assert is_nil(Map.get(alloc_0, :activity_coverage_percent))

      alloc_1 = Enum.at(timespan_0314.allocations, 1)
      assert DateTime.compare(activity_start_time, alloc_1.start_time) == :eq
      assert DateTime.compare(activity_end_time, alloc_1.end_time) == :eq
      assert DateTime.diff(activity_end_time, activity_start_time) == alloc_1.duration_seconds
      assert alloc_1.activity_id == activity.id
      assert alloc_1.activity_coverage_percent == 1
      assert alloc_1.activity_extends_before == false
      assert alloc_1.activity_extends_after == false

      assert Enum.empty?(timespans_0315)
    end

    test "Deals with overlapping shifts and activities - 3" do
      user =
        Factory.create_user(%{
          timezone: "America/Los_Angeles"
        })

      # Shift: 12:15pm - 4:15pm
      shift_start_time = get_utc_date(~N[2023-03-14T12:15:00Z], user.timezone)
      shift_end_time = get_utc_date(~N[2023-03-14T16:15:00Z], user.timezone)

      shift =
        Factory.create_shift(%{
          user_id: user.id,
          start_time: shift_start_time,
          end_time: shift_end_time
        })

      # Activity: 11:30am - 2:15pm
      activity_start_time = get_utc_date(~N[2023-03-14T11:30:00Z], user.timezone)
      activity_end_time = get_utc_date(~N[2023-03-14T14:15:00Z], user.timezone)

      activity =
        Factory.create_activity(user.id, %{
          "timezone" => user.timezone,
          "employer" => "uber",
          "duration" => 1200,
          "distance" => "10.3",
          "earning_type" => "work",
          "status" => "completed",
          "num_tasks" => 3,
          "start_date" => activity_start_time,
          "end_date" => activity_end_time
        })

      timespans_0313 =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-13],
          "user_facing"
        )

      timespans_0314 =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-14],
          "user_facing"
        )

      timespans_0315 =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-15],
          "user_facing"
        )

      assert Enum.empty?(timespans_0313)

      assert Enum.count(timespans_0314) == 1
      timespan_0314 = Enum.at(timespans_0314, 0)
      assert DateTime.compare(activity_start_time, timespan_0314.start_time) == :eq
      assert DateTime.compare(shift_end_time, timespan_0314.end_time) == :eq
      assert timespan_0314.shift_ids == [shift.id]

      assert Enum.count(timespan_0314.allocations) == 2

      alloc_0 = Enum.at(timespan_0314.allocations, 0)
      assert DateTime.compare(activity_start_time, alloc_0.start_time) == :eq
      assert DateTime.compare(activity_end_time, alloc_0.end_time) == :eq
      assert DateTime.diff(activity_end_time, activity_start_time) == alloc_0.duration_seconds
      assert alloc_0.activity_id == activity.id
      assert alloc_0.activity_coverage_percent == 1
      assert alloc_0.activity_extends_before == false
      assert alloc_0.activity_extends_after == false

      alloc_1 = Enum.at(timespan_0314.allocations, 1)
      assert DateTime.compare(activity_end_time, alloc_1.start_time) == :eq
      assert DateTime.compare(shift_end_time, alloc_1.end_time) == :eq
      assert DateTime.diff(shift_end_time, activity_end_time) == alloc_1.duration_seconds
      assert is_nil(Map.get(alloc_1, :activity_id))
      assert is_nil(Map.get(alloc_1, :activity_coverage_percent))

      assert Enum.empty?(timespans_0315)
    end

    test "Does not put future dated timespans when shift is open" do
      timezone = "America/Los_Angeles"

      user =
        Factory.create_user(%{
          timezone: timezone
        })

      now = DateTime.utc_now()
      work_day = DateTimeUtil.datetime_to_working_day(now, timezone)
      [work_day_start, _work_day_end] = User.working_day_bounds(work_day, user)

      # Shift: 45min ago - open
      shift_start_time = DateTime.add(now, -45, :minute)

      Factory.create_shift(%{
        user_id: user.id,
        start_time: shift_start_time,
        end_time: nil
      })

      # Activity: 55min ago - 30min future
      activity_start_time = DateTime.add(now, -55, :minute)
      activity_end_time = DateTime.add(now, 30, :minute)

      Factory.create_activity(user.id, %{
        "timezone" => user.timezone,
        "employer" => "uber",
        "duration" => 1200,
        "distance" => "10.3",
        "earning_type" => "work",
        "status" => "completed",
        "num_tasks" => 3,
        "start_date" => activity_start_time,
        "end_date" => activity_end_time
      })

      timespans =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          work_day,
          "user_facing"
        )

      expected_start_time =
        Enum.max([activity_start_time, work_day_start], DateTime)
        |> DateTimeUtil.floor_minute()

      expected_end_time = DateTimeUtil.ceiling_minute(now)
      timespan = Enum.at(timespans, 0)

      # should be 1 timespan convering the shift and the job since they overlap
      assert Enum.count(timespans) == 1

      # should be at the start of the job since it is before the shift started
      assert DateTime.compare(timespan.start_time, expected_start_time) == :eq

      # should be about now since the shift is open ended
      assert_in_delta(
        DateTime.to_unix(timespan.end_time),
        DateTime.to_unix(expected_end_time),
        60
      )

      allocation = Enum.at(timespan.allocations, 0)

      # there should only be 1 allocation
      assert Enum.count(timespan.allocations) == 1

      assert DateTime.compare(allocation.start_time, expected_start_time) == :eq

      assert_in_delta(
        DateTime.to_unix(allocation.end_time),
        DateTime.to_unix(expected_end_time),
        60
      )
    end

    test "Combines activities into timespan if they occur within 30-minutes gap" do
      user =
        Factory.create_user(%{
          timezone: "America/Los_Angeles"
        })

      # Activity: 11:30am - 2:15pm
      activity1_start_time = get_utc_date(~N[2023-03-14T11:30:00Z], user.timezone)
      activity1_end_time = get_utc_date(~N[2023-03-14T14:15:00Z], user.timezone)

      activity1 =
        Factory.create_activity(user.id, %{
          "timezone" => user.timezone,
          "employer" => "uber",
          "duration" => 1200,
          "distance" => "10.3",
          "earning_type" => "work",
          "status" => "completed",
          "num_tasks" => 3,
          "start_date" => activity1_start_time,
          "end_date" => activity1_end_time
        })

      # Activity: 2:20pm - 3:15pm
      activity2_start_time = get_utc_date(~N[2023-03-14T14:20:00Z], user.timezone)
      activity2_end_time = get_utc_date(~N[2023-03-14T15:15:00Z], user.timezone)

      activity2 =
        Factory.create_activity(user.id, %{
          "timezone" => user.timezone,
          "employer" => "uber",
          "duration" => 1200,
          "distance" => "10.3",
          "earning_type" => "work",
          "status" => "completed",
          "num_tasks" => 3,
          "start_date" => activity2_start_time,
          "end_date" => activity2_end_time
        })

      timespans_0313 =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-13],
          "user_facing"
        )

      timespans_0314 =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-14],
          "user_facing"
        )

      timespans_0315 =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-15],
          "user_facing"
        )

      assert Enum.empty?(timespans_0313)

      assert Enum.count(timespans_0314) == 1
      timespan_0314 = Enum.at(timespans_0314, 0)
      assert DateTime.compare(activity1_start_time, timespan_0314.start_time) == :eq
      assert DateTime.compare(activity2_end_time, timespan_0314.end_time) == :eq

      assert Enum.count(timespan_0314.allocations) == 3

      alloc_0 = Enum.at(timespan_0314.allocations, 0)
      assert DateTime.compare(activity1_start_time, alloc_0.start_time) == :eq
      assert DateTime.compare(activity1_end_time, alloc_0.end_time) == :eq
      assert DateTime.diff(activity1_end_time, activity1_start_time) == alloc_0.duration_seconds
      assert alloc_0.activity_id == activity1.id
      assert alloc_0.activity_coverage_percent == 1
      assert alloc_0.activity_extends_before == false
      assert alloc_0.activity_extends_after == false

      alloc_1 = Enum.at(timespan_0314.allocations, 1)
      assert DateTime.compare(activity1_end_time, alloc_1.start_time) == :eq
      assert DateTime.compare(activity2_start_time, alloc_1.end_time) == :eq
      assert DateTime.diff(activity2_start_time, activity1_end_time) == alloc_1.duration_seconds
      assert is_nil(Map.get(alloc_1, :activity_id))
      assert is_nil(Map.get(alloc_1, :activity_coverage_percent))

      alloc_2 = Enum.at(timespan_0314.allocations, 2)
      assert DateTime.compare(activity2_start_time, alloc_2.start_time) == :eq
      assert DateTime.compare(activity2_end_time, alloc_2.end_time) == :eq
      assert DateTime.diff(activity2_end_time, activity2_start_time) == alloc_2.duration_seconds
      assert alloc_2.activity_id == activity2.id
      assert alloc_2.activity_coverage_percent == 1
      assert alloc_2.activity_extends_before == false
      assert alloc_2.activity_extends_after == false

      assert Enum.empty?(timespans_0315)
    end

    test "Breaks activities into separate timespans if they occur greater than 30-minutes apart" do
      user =
        Factory.create_user(%{
          timezone: "America/Los_Angeles"
        })

      # Activity: 11:30am - 2:15pm
      activity1_start_time = get_utc_date(~N[2023-03-14T11:30:00Z], user.timezone)
      activity1_end_time = get_utc_date(~N[2023-03-14T14:15:00Z], user.timezone)

      Factory.create_activity(user.id, %{
        "timezone" => user.timezone,
        "employer" => "uber",
        "duration" => 1200,
        "distance" => "10.3",
        "earning_type" => "work",
        "status" => "completed",
        "num_tasks" => 3,
        "start_date" => activity1_start_time,
        "end_date" => activity1_end_time
      })

      # Activity: 2:46pm - 3:15pm
      activity2_start_time = get_utc_date(~N[2023-03-14T14:46:00Z], user.timezone)
      activity2_end_time = get_utc_date(~N[2023-03-14T15:15:00Z], user.timezone)

      Factory.create_activity(user.id, %{
        "timezone" => user.timezone,
        "employer" => "uber",
        "duration" => 1200,
        "distance" => "10.3",
        "earning_type" => "work",
        "status" => "completed",
        "num_tasks" => 3,
        "start_date" => activity2_start_time,
        "end_date" => activity2_end_time
      })

      timespans_0313 =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-13],
          "user_facing"
        )

      timespans_0314 =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-14],
          "user_facing"
        )

      timespans_0315 =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-15],
          "user_facing"
        )

      assert Enum.empty?(timespans_0313)

      assert Enum.count(timespans_0314) == 2
      timespan_0314_0 = Enum.at(timespans_0314, 0)
      assert DateTime.compare(activity1_start_time, timespan_0314_0.start_time) == :eq
      assert DateTime.compare(activity1_end_time, timespan_0314_0.end_time) == :eq

      timespan_0314_1 = Enum.at(timespans_0314, 1)
      assert DateTime.compare(activity2_start_time, timespan_0314_1.start_time) == :eq
      assert DateTime.compare(activity2_end_time, timespan_0314_1.end_time) == :eq

      assert Enum.empty?(timespans_0315)
    end

    test "Does not break activities that are encompassed as part of a shift" do
      user =
        Factory.create_user(%{
          timezone: "America/Los_Angeles"
        })

      # Shift: 09:15am - 5:15pm
      shift_start_time = get_utc_date(~N[2023-03-14T09:15:00Z], user.timezone)
      shift_end_time = get_utc_date(~N[2023-03-14T17:15:00Z], user.timezone)

      shift =
        Factory.create_shift(%{
          user_id: user.id,
          start_time: shift_start_time,
          end_time: shift_end_time
        })

      # Activity: 11:30am - 2:15pm
      activity1_start_time = get_utc_date(~N[2023-03-14T11:30:00Z], user.timezone)
      activity1_end_time = get_utc_date(~N[2023-03-14T14:15:00Z], user.timezone)

      activity1 =
        Factory.create_activity(user.id, %{
          "timezone" => user.timezone,
          "employer" => "uber",
          "duration" => 1200,
          "distance" => "10.3",
          "earning_type" => "work",
          "status" => "completed",
          "num_tasks" => 3,
          "start_date" => activity1_start_time,
          "end_date" => activity1_end_time
        })

      # Activity: 3:00pm - 3:15pm
      activity2_start_time = get_utc_date(~N[2023-03-14T15:00:00Z], user.timezone)
      activity2_end_time = get_utc_date(~N[2023-03-14T15:15:00Z], user.timezone)

      activity2 =
        Factory.create_activity(user.id, %{
          "timezone" => user.timezone,
          "employer" => "uber",
          "duration" => 1200,
          "distance" => "10.3",
          "earning_type" => "work",
          "status" => "completed",
          "num_tasks" => 3,
          "start_date" => activity2_start_time,
          "end_date" => activity2_end_time
        })

      timespans_0313 =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-13],
          "user_facing"
        )

      timespans_0314 =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-14],
          "user_facing"
        )

      timespans_0315 =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-15],
          "user_facing"
        )

      assert Enum.empty?(timespans_0313)

      assert Enum.count(timespans_0314) == 1
      timespan_0314 = Enum.at(timespans_0314, 0)
      assert DateTime.compare(shift_start_time, timespan_0314.start_time) == :eq
      assert DateTime.compare(shift_end_time, timespan_0314.end_time) == :eq
      assert timespan_0314.shift_ids == [shift.id]
      assert Enum.count(timespan_0314.allocations) == 5

      alloc_0 = Enum.at(timespan_0314.allocations, 0)
      assert DateTime.compare(shift_start_time, alloc_0.start_time) == :eq
      assert DateTime.compare(activity1_start_time, alloc_0.end_time) == :eq
      assert DateTime.diff(activity1_start_time, shift_start_time) == alloc_0.duration_seconds
      assert is_nil(Map.get(alloc_0, :activity_id))
      assert is_nil(Map.get(alloc_0, :activity_coverage_percent))

      alloc_1 = Enum.at(timespan_0314.allocations, 1)
      assert DateTime.compare(activity1_start_time, alloc_1.start_time) == :eq
      assert DateTime.compare(activity1_end_time, alloc_1.end_time) == :eq
      assert DateTime.diff(activity1_end_time, activity1_start_time) == alloc_1.duration_seconds
      assert alloc_1.activity_id == activity1.id
      assert alloc_1.activity_coverage_percent == 1
      assert alloc_1.activity_extends_before == false
      assert alloc_1.activity_extends_after == false

      alloc_2 = Enum.at(timespan_0314.allocations, 2)
      assert DateTime.compare(activity1_end_time, alloc_2.start_time) == :eq
      assert DateTime.compare(activity2_start_time, alloc_2.end_time) == :eq
      assert DateTime.diff(activity2_start_time, activity1_end_time) == alloc_2.duration_seconds
      assert is_nil(Map.get(alloc_2, :activity_id))
      assert is_nil(Map.get(alloc_2, :activity_coverage_percent))

      alloc_3 = Enum.at(timespan_0314.allocations, 3)
      assert DateTime.compare(activity2_start_time, alloc_3.start_time) == :eq
      assert DateTime.compare(activity2_end_time, alloc_3.end_time) == :eq
      assert DateTime.diff(activity2_end_time, activity2_start_time) == alloc_3.duration_seconds
      assert alloc_3.activity_id == activity2.id
      assert alloc_3.activity_coverage_percent == 1
      assert alloc_3.activity_extends_before == false
      assert alloc_3.activity_extends_after == false

      alloc_4 = Enum.at(timespan_0314.allocations, 4)
      assert DateTime.compare(activity2_end_time, alloc_4.start_time) == :eq
      assert DateTime.compare(shift_end_time, alloc_4.end_time) == :eq
      assert DateTime.diff(shift_end_time, activity2_end_time) == alloc_4.duration_seconds
      assert is_nil(Map.get(alloc_4, :activity_id))
      assert is_nil(Map.get(alloc_4, :activity_coverage_percent))

      assert Enum.empty?(timespans_0315)
    end

    test "Excludes non-work, deleted, incomplete items" do
      user =
        Factory.create_user(%{
          timezone: "America/Los_Angeles"
        })

      # Activity: 11:30am - 2:15pm (Incentive)
      activity1_start_time = get_utc_date(~N[2023-03-14T11:30:00Z], user.timezone)
      activity1_end_time = get_utc_date(~N[2023-03-14T14:15:00Z], user.timezone)

      Factory.create_activity(user.id, %{
        "timezone" => user.timezone,
        "employer" => "uber",
        "duration" => 1200,
        "distance" => "10.3",
        "earning_type" => "incentive",
        "status" => "completed",
        "num_tasks" => 3,
        "start_date" => activity1_start_time,
        "end_date" => activity1_end_time
      })

      # Activity: 3:00pm - 3:15pm (In progress)
      activity2_start_time = get_utc_date(~N[2023-03-14T15:00:00Z], user.timezone)
      activity2_end_time = get_utc_date(~N[2023-03-14T15:15:00Z], user.timezone)

      Factory.create_activity(user.id, %{
        "timezone" => user.timezone,
        "employer" => "uber",
        "duration" => 1200,
        "distance" => "10.3",
        "earning_type" => "work",
        "status" => "who knows",
        "num_tasks" => 3,
        "start_date" => activity2_start_time,
        "end_date" => activity2_end_time
      })

      # Activity: 3:00pm - 3:15pm (deleted)
      activity3_start_time = get_utc_date(~N[2023-03-14T15:00:00Z], user.timezone)
      activity3_end_time = get_utc_date(~N[2023-03-14T15:15:00Z], user.timezone)

      Factory.create_activity(
        user.id,
        %{
          "timezone" => user.timezone,
          "employer" => "uber",
          "duration" => 1200,
          "distance" => "10.3",
          "earning_type" => "work",
          "status" => "who knows",
          "num_tasks" => 3,
          "start_date" => activity3_start_time,
          "end_date" => activity3_end_time
        },
        true
      )

      timespans_0313 =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-13],
          "user_facing"
        )

      timespans_0314 =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-14],
          "user_facing"
        )

      timespans_0315 =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-15],
          "user_facing"
        )

      assert Enum.empty?(timespans_0313)
      assert Enum.empty?(timespans_0314)
      assert Enum.empty?(timespans_0315)
    end

    test "Includes work items with status of completed and cancelled" do
      user =
        Factory.create_user(%{
          timezone: "America/Los_Angeles"
        })

      # Activity: 11:30am - 2:15pm (Incentive)
      activity1_start_time = get_utc_date(~N[2023-03-14T11:30:00Z], user.timezone)
      activity1_end_time = get_utc_date(~N[2023-03-14T14:15:00Z], user.timezone)

      Factory.create_activity(user.id, %{
        "timezone" => user.timezone,
        "employer" => "uber",
        "duration" => 1200,
        "distance" => "10.3",
        "earning_type" => "work",
        "status" => "completed",
        "num_tasks" => 3,
        "start_date" => activity1_start_time,
        "end_date" => activity1_end_time
      })

      # Activity: 2:25pm - 3:15pm (In progress)
      activity2_start_time = get_utc_date(~N[2023-03-14T14:25:00Z], user.timezone)
      activity2_end_time = get_utc_date(~N[2023-03-14T15:15:00Z], user.timezone)

      Factory.create_activity(user.id, %{
        "timezone" => user.timezone,
        "employer" => "uber",
        "duration" => 1200,
        "distance" => "10.3",
        "earning_type" => "work",
        "status" => "cancelled",
        "num_tasks" => 3,
        "start_date" => activity2_start_time,
        "end_date" => activity2_end_time
      })

      timespans_0313 =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-13],
          "user_facing"
        )

      timespans_0314 =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-14],
          "user_facing"
        )

      timespans_0315 =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-15],
          "user_facing"
        )

      assert Enum.empty?(timespans_0313)

      assert Enum.count(timespans_0314) == 1
      timespan_0314 = Enum.at(timespans_0314, 0)
      assert DateTime.compare(activity1_start_time, timespan_0314.start_time) == :eq
      assert DateTime.compare(activity2_end_time, timespan_0314.end_time) == :eq

      assert Enum.empty?(timespans_0315)
    end

    test "Rounds Shifts and Activities to the minute" do
      user =
        Factory.create_user(%{
          timezone: "America/Los_Angeles"
        })

      # Shift: 09:15am - 10:14:38am
      shift_start_time = get_utc_date(~N[2023-03-14T09:15:03Z], user.timezone)
      shift_end_time = get_utc_date(~N[2023-03-14T10:14:38Z], user.timezone)

      Factory.create_shift(%{
        user_id: user.id,
        start_time: shift_start_time,
        end_time: shift_end_time
      })

      shift_start_time = DateTimeUtil.floor_minute(shift_start_time)
      shift_end_time = DateTimeUtil.ceiling_minute(shift_end_time)

      # Activity: 11:30am - 2:15pm
      activity1_start_time = get_utc_date(~N[2023-03-14T11:30:10Z], user.timezone)
      activity1_end_time = get_utc_date(~N[2023-03-14T14:15:03Z], user.timezone)

      Factory.create_activity(user.id, %{
        "timezone" => user.timezone,
        "employer" => "uber",
        "duration" => 1200,
        "distance" => "10.3",
        "earning_type" => "work",
        "status" => "completed",
        "num_tasks" => 3,
        "start_date" => activity1_start_time,
        "end_date" => activity1_end_time
      })

      activity1_start_time = DateTimeUtil.floor_minute(activity1_start_time)

      # Activity: 2:20:20pm - 3:15pm
      activity2_start_time = get_utc_date(~N[2023-03-14T14:20:20Z], user.timezone)
      activity2_end_time = get_utc_date(~N[2023-03-14T15:15:00Z], user.timezone)

      Factory.create_activity(user.id, %{
        "timezone" => user.timezone,
        "employer" => "uber",
        "duration" => 1200,
        "distance" => "10.3",
        "earning_type" => "work",
        "status" => "completed",
        "num_tasks" => 3,
        "start_date" => activity2_start_time,
        "end_date" => activity2_end_time
      })

      activity2_end_time = DateTimeUtil.ceiling_minute(activity2_end_time)

      timespans_0313 =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-13],
          "user_facing"
        )

      timespans_0314 =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-14],
          "user_facing"
        )

      timespans_0315 =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-15],
          "user_facing"
        )

      assert Enum.empty?(timespans_0313)

      assert Enum.count(timespans_0314) == 2
      timespan_0314_0 = Enum.at(timespans_0314, 0)
      assert DateTime.compare(shift_start_time, timespan_0314_0.start_time) == :eq
      assert DateTime.compare(shift_end_time, timespan_0314_0.end_time) == :eq

      timespan_0314_1 = Enum.at(timespans_0314, 1)
      assert DateTime.compare(activity1_start_time, timespan_0314_1.start_time) == :eq
      assert DateTime.compare(activity2_end_time, timespan_0314_1.end_time) == :eq

      assert Enum.empty?(timespans_0315)
    end

    test "Captures Engaged and Not Engaged Duration Correctly - 1" do
      user =
        Factory.create_user(%{
          timezone: "America/Los_Angeles"
        })

      # Shift: 09:15am - 12:15am
      shift_start_time = get_utc_date(~N[2023-03-14T09:15:00Z], user.timezone)
      shift_end_time = get_utc_date(~N[2023-03-14T12:15:00Z], user.timezone)

      Factory.create_shift(%{
        user_id: user.id,
        start_time: shift_start_time,
        end_time: shift_end_time
      })

      # Activity: 9:30am - 11:30am
      activity1_start_time = get_utc_date(~N[2023-03-14T09:30:00Z], user.timezone)
      activity1_end_time = get_utc_date(~N[2023-03-14T11:30:00Z], user.timezone)

      Factory.create_activity(user.id, %{
        "timezone" => user.timezone,
        "employer" => "uber",
        "duration" => 1200,
        "distance" => "10.3",
        "earning_type" => "work",
        "status" => "completed",
        "num_tasks" => 3,
        "start_date" => activity1_start_time,
        "end_date" => activity1_end_time
      })

      # Activity: 10:30am - 12:00pm
      activity2_start_time = get_utc_date(~N[2023-03-14T10:30:00Z], user.timezone)
      activity2_end_time = get_utc_date(~N[2023-03-14T12:00:00Z], user.timezone)

      Factory.create_activity(user.id, %{
        "timezone" => user.timezone,
        "employer" => "uber",
        "duration" => 1200,
        "distance" => "10.3",
        "earning_type" => "work",
        "status" => "completed",
        "num_tasks" => 3,
        "start_date" => activity2_start_time,
        "end_date" => activity2_end_time
      })

      timespans_0313 =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-13],
          "user_facing"
        )

      timespans_0314 =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-14],
          "user_facing"
        )

      timespans_0315 =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-15],
          "user_facing"
        )

      assert Enum.empty?(timespans_0313)

      assert Enum.count(timespans_0314) == 1
      timespan_0314 = Enum.at(timespans_0314, 0)
      assert DateTime.compare(shift_start_time, timespan_0314.start_time) == :eq
      assert DateTime.compare(shift_end_time, timespan_0314.end_time) == :eq
      assert timespan_0314.duration_seconds == 3 * 60 * 60
      assert timespan_0314.duration_seconds_engaged == 150 * 60

      assert Enum.empty?(timespans_0315)
    end

    test "Captures Engaged and Not Engaged Duration Correctly - 2" do
      user =
        Factory.create_user(%{
          timezone: "America/Los_Angeles"
        })

      # Activity: 9:30am - 11:30am
      activity1_start_time = get_utc_date(~N[2023-03-14T09:30:00Z], user.timezone)
      activity1_end_time = get_utc_date(~N[2023-03-14T11:30:00Z], user.timezone)

      Factory.create_activity(user.id, %{
        "timezone" => user.timezone,
        "employer" => "uber",
        "duration" => 1200,
        "distance" => "10.3",
        "earning_type" => "work",
        "status" => "completed",
        "num_tasks" => 3,
        "start_date" => activity1_start_time,
        "end_date" => activity1_end_time
      })

      # Activity: 11:40am - 12:00pm
      activity2_start_time = get_utc_date(~N[2023-03-14T11:40:00Z], user.timezone)
      activity2_end_time = get_utc_date(~N[2023-03-14T12:00:00Z], user.timezone)

      Factory.create_activity(user.id, %{
        "timezone" => user.timezone,
        "employer" => "uber",
        "duration" => 1200,
        "distance" => "10.3",
        "earning_type" => "work",
        "status" => "completed",
        "num_tasks" => 3,
        "start_date" => activity2_start_time,
        "end_date" => activity2_end_time
      })

      timespans_0313 =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-13],
          "user_facing"
        )

      timespans_0314 =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-14],
          "user_facing"
        )

      timespans_0315 =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-15],
          "user_facing"
        )

      assert Enum.empty?(timespans_0313)

      assert Enum.count(timespans_0314) == 1
      timespan_0314 = Enum.at(timespans_0314, 0)
      assert DateTime.compare(activity1_start_time, timespan_0314.start_time) == :eq
      assert DateTime.compare(activity2_end_time, timespan_0314.end_time) == :eq

      assert timespan_0314.duration_seconds ==
               DateTime.diff(activity2_end_time, activity1_start_time)

      assert timespan_0314.duration_seconds_engaged ==
               DateTime.diff(activity1_end_time, activity1_start_time) +
                 DateTime.diff(activity2_end_time, activity2_start_time)

      assert Enum.empty?(timespans_0315)
    end

    test "Estimates Device mileage for timespan" do
      user =
        Factory.create_user(%{
          timezone: "America/Los_Angeles"
        })

      shift_start_time = get_utc_date(~N[2023-03-14T23:15:00Z], user.timezone)
      shift_end_time = get_utc_date(~N[2023-03-14T23:45:00Z], user.timezone)

      Factory.create_shift(%{
        user_id: user.id,
        start_time: shift_start_time,
        end_time: shift_end_time
      })

      point_stats = create_points(user.id, shift_start_time, shift_end_time, 8)

      timespans =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-14],
          "user_facing"
        )

      timespan = Enum.at(timespans, 0)

      # 80% samples over 100% of the time should be 80% quality
      assert_in_delta(timespan.device_miles_quality_percent, 0.8, 0.05)

      # if 100% coverage, the estimate would be 2x
      assert timespan.device_miles == point_stats.device_miles

      assert timespan.device_miles_deduction_cents ==
               Irs.calculate_irs_expense(timespan.start_time, timespan.device_miles)

      assert Enum.count(timespan.allocations) == 1

      alloc_0 = Enum.at(timespan.allocations, 0)
      assert DateTime.compare(shift_start_time, alloc_0.start_time) == :eq
      assert DateTime.compare(shift_end_time, alloc_0.end_time) == :eq
      assert DateTime.diff(shift_end_time, shift_start_time) == alloc_0.duration_seconds
      assert is_nil(Map.get(alloc_0, :activity_id))
      assert is_nil(Map.get(alloc_0, :activity_coverage_percent))
      assert alloc_0.device_miles == point_stats.device_miles

      assert alloc_0.device_miles_deduction_cents ==
               Irs.calculate_irs_expense(timespan.start_time, alloc_0.device_miles)

      assert_in_delta(alloc_0.device_miles_quality_percent, 0.8, 0.05)
    end

    test "Estimates Device mileage for timespan with incomplete data" do
      user =
        Factory.create_user(%{
          timezone: "America/Los_Angeles"
        })

      shift_start_time = get_utc_date(~N[2023-03-14T23:15:00Z], user.timezone)
      midpoint_time = get_utc_date(~N[2023-03-14T23:30:00Z], user.timezone)
      shift_end_time = get_utc_date(~N[2023-03-14T23:45:00Z], user.timezone)

      Factory.create_shift(%{
        user_id: user.id,
        start_time: shift_start_time,
        end_time: shift_end_time
      })

      # capture the actual point stats created.
      point_stats = create_points(user.id, shift_start_time, midpoint_time, 8)

      timespans =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-14],
          "user_facing"
        )

      timespan = Enum.at(timespans, 0)

      # 80% samples over 50% of the time should be 40% quality
      assert_in_delta(timespan.device_miles_quality_percent, 0.4, 0.1)

      # if 50% coverage, the estimate would be 2x
      assert timespan.device_miles == point_stats.device_miles * 2

      assert timespan.device_miles_deduction_cents ==
               Irs.calculate_irs_expense(timespan.start_time, timespan.device_miles)
    end

    test "Estimates Device mileage for timespan that cross day boundary" do
      user =
        Factory.create_user(%{
          timezone: "America/Los_Angeles"
        })

      shift_start_time = get_utc_date(~N[2023-02-12T02:00:00Z], user.timezone)
      shift_end_time = get_utc_date(~N[2023-02-12T06:00:00Z], user.timezone)

      Factory.create_shift(%{
        user_id: user.id,
        start_time: shift_start_time,
        end_time: shift_end_time
      })

      point_stats = create_points(user.id, shift_start_time, shift_end_time, 8)

      timespans_0211 =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-02-11],
          "user_facing"
        )

      timespan_0211 = Enum.at(timespans_0211, 0)

      timespans_0212 =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-02-12],
          "user_facing"
        )

      timespan_0212 = Enum.at(timespans_0212, 0)

      assert_in_delta(timespan_0211.device_miles, point_stats.device_miles / 2, 0.1)
      assert_in_delta(timespan_0212.device_miles, point_stats.device_miles / 2, 0.1)
    end

    test "Estimates Device engaged mileage for timespan" do
      user =
        Factory.create_user(%{
          timezone: "America/Los_Angeles"
        })

      shift_start_time = get_utc_date(~N[2023-03-14T23:00:00Z], user.timezone)
      shift_end_time = get_utc_date(~N[2023-03-15T00:00:00Z], user.timezone)

      Factory.create_shift(%{
        user_id: user.id,
        start_time: shift_start_time,
        end_time: shift_end_time
      })

      # Activity: 11:10am - 11:30pm
      activity1_start_time = get_utc_date(~N[2023-03-14T23:10:00Z], user.timezone)
      activity1_end_time = get_utc_date(~N[2023-03-14T23:30:00Z], user.timezone)

      Factory.create_activity(user.id, %{
        "timezone" => user.timezone,
        "employer" => "uber",
        "duration" => 1200,
        "distance" => "10.3",
        "earning_type" => "work",
        "status" => "completed",
        "num_tasks" => 3,
        "start_date" => activity1_start_time,
        "end_date" => activity1_end_time
      })

      # Activity: 2:30pm - 3:15pm
      activity2_start_time = get_utc_date(~N[2023-03-14T23:40:00Z], user.timezone)
      activity2_end_time = get_utc_date(~N[2023-03-14T23:50:00Z], user.timezone)

      Factory.create_activity(user.id, %{
        "timezone" => user.timezone,
        "employer" => "uber",
        "duration" => 1200,
        "distance" => "10.3",
        "earning_type" => "work",
        "status" => "completed",
        "num_tasks" => 3,
        "start_date" => activity2_start_time,
        "end_date" => activity2_end_time
      })

      # capture the actual point stats created.
      point_stats = create_points(user.id, shift_start_time, shift_end_time, 8)

      timespans =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-14],
          "user_facing"
        )

      timespan = Enum.at(timespans, 0)

      # 50% of the shift is covered by activities, so 50% of the mileage should
      assert_in_delta(point_stats.device_miles, timespan.device_miles_engaged * 2, 0.1)

      assert timespan.device_miles_deduction_cents_engaged ==
               Irs.calculate_irs_expense(timespan.start_time, timespan.device_miles_engaged)
    end

    test "Estimates Device engaged mileage for timespan with overlapping activities" do
      user =
        Factory.create_user(%{
          timezone: "America/Los_Angeles"
        })

      shift_start_time = get_utc_date(~N[2023-03-14T23:00:00Z], user.timezone)
      shift_end_time = get_utc_date(~N[2023-03-15T00:00:00Z], user.timezone)

      Factory.create_shift(%{
        user_id: user.id,
        start_time: shift_start_time,
        end_time: shift_end_time
      })

      # Activity: 11:10pm - 11:30pm
      activity1_start_time = get_utc_date(~N[2023-03-14T23:10:00Z], user.timezone)
      activity1_end_time = get_utc_date(~N[2023-03-14T23:30:00Z], user.timezone)

      Factory.create_activity(user.id, %{
        "timezone" => user.timezone,
        "employer" => "uber",
        "duration" => 1200,
        "distance" => "10.3",
        "earning_type" => "work",
        "status" => "completed",
        "num_tasks" => 3,
        "start_date" => activity1_start_time,
        "end_date" => activity1_end_time
      })

      # Activity: 11:10pm - 11:40pm
      activity2_start_time = get_utc_date(~N[2023-03-14T23:20:00Z], user.timezone)
      activity2_end_time = get_utc_date(~N[2023-03-14T23:40:00Z], user.timezone)

      Factory.create_activity(user.id, %{
        "timezone" => user.timezone,
        "employer" => "uber",
        "duration" => 1200,
        "distance" => "10.3",
        "earning_type" => "work",
        "status" => "completed",
        "num_tasks" => 3,
        "start_date" => activity2_start_time,
        "end_date" => activity2_end_time
      })

      # capture the actual point stats created.
      point_stats = create_points(user.id, shift_start_time, shift_end_time, 8)

      timespans =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-14],
          "user_facing"
        )

      timespan = Enum.at(timespans, 0)

      # 50% of the shift is covered by activities, so 50% of the mileage should
      assert_in_delta(point_stats.device_miles, timespan.device_miles_engaged * 2, 0.1)

      assert timespan.device_miles_deduction_cents_engaged ==
               Irs.calculate_irs_expense(timespan.start_time, timespan.device_miles_engaged)
    end

    test "Estimates Platform mileage for timespan" do
      user =
        Factory.create_user(%{
          timezone: "America/Los_Angeles"
        })

      # Activity: 11:10pm - 11:30pm
      activity1_start_time = get_utc_date(~N[2023-03-13T23:10:00Z], user.timezone)
      activity1_end_time = get_utc_date(~N[2023-03-13T23:40:00Z], user.timezone)

      Factory.create_activity(user.id, %{
        "timezone" => user.timezone,
        "employer" => "uber",
        "duration" => 1200,
        "distance" => "30",
        "earning_type" => "work",
        "status" => "completed",
        "num_tasks" => 3,
        "start_date" => activity1_start_time,
        "end_date" => activity1_end_time
      })

      # Activity: 11:10pm - 11:40pm
      activity2_start_time = get_utc_date(~N[2023-03-13T23:40:00Z], user.timezone)
      activity2_end_time = get_utc_date(~N[2023-03-14T00:00:00Z], user.timezone)

      Factory.create_activity(user.id, %{
        "timezone" => user.timezone,
        "employer" => "uber",
        "duration" => 1200,
        "distance" => "20",
        "earning_type" => "work",
        "status" => "completed",
        "num_tasks" => 3,
        "start_date" => activity2_start_time,
        "end_date" => activity2_end_time
      })

      timespans =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-13],
          "user_facing"
        )

      timespan = Enum.at(timespans, 0)

      assert timespan.platform_miles_quality_percent == 1.0
      assert timespan.platform_miles == 50.0
      assert timespan.platform_miles_deduction_cents_engaged == 3275
      assert timespan.platform_miles_engaged == 50.0
      assert timespan.platform_miles_deduction_cents_engaged == 3275
    end

    test "Estimates Platform mileage for timespan with overlapping jobs" do
      user =
        Factory.create_user(%{
          timezone: "America/Los_Angeles"
        })

      # Activity: 11:10pm - 11:40pm
      activity1_start_time = get_utc_date(~N[2023-03-13T23:10:00Z], user.timezone)
      activity1_end_time = get_utc_date(~N[2023-03-13T23:40:00Z], user.timezone)

      Factory.create_activity(user.id, %{
        "timezone" => user.timezone,
        "employer" => "uber",
        "duration" => 1200,
        "distance" => "30",
        "earning_type" => "work",
        "status" => "completed",
        "num_tasks" => 3,
        "start_date" => activity1_start_time,
        "end_date" => activity1_end_time
      })

      # Activity: 11:30pm - 12:00am
      activity2_start_time = get_utc_date(~N[2023-03-13T23:30:00Z], user.timezone)
      activity2_end_time = get_utc_date(~N[2023-03-14T00:00:00Z], user.timezone)

      Factory.create_activity(user.id, %{
        "timezone" => user.timezone,
        "employer" => "uber",
        "duration" => 1200,
        "distance" => "60",
        "earning_type" => "work",
        "status" => "completed",
        "num_tasks" => 3,
        "start_date" => activity2_start_time,
        "end_date" => activity2_end_time
      })

      timespans =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-13],
          "user_facing"
        )

      timespan = Enum.at(timespans, 0)

      # 11:10 - 11:30     1mile/min                                 = 20
      # 11:30 - 11:40     1mile/min or 2mile/min --> 1.5mile/min    = 15
      # 11:40 - 12:00     2mile/min                                 = 40
      assert timespan.platform_miles_quality_percent == 1.0
      assert timespan.platform_miles == 75.0
      assert timespan.platform_miles_deduction_cents == 4913
      assert timespan.platform_miles_engaged == 75.0
      assert timespan.platform_miles_deduction_cents_engaged == 4913
    end

    test "Estimates Platform mileage for timespan with incomplete data" do
      user =
        Factory.create_user(%{
          timezone: "America/Los_Angeles"
        })

      # Activity: 11:00pm - 11:15pm
      activity1_start_time = get_utc_date(~N[2023-03-13T23:00:00Z], user.timezone)
      activity1_end_time = get_utc_date(~N[2023-03-13T23:15:00Z], user.timezone)

      Factory.create_activity(user.id, %{
        "timezone" => user.timezone,
        "employer" => "uber",
        "duration" => 1200,
        "distance" => "30",
        "earning_type" => "work",
        "status" => "completed",
        "num_tasks" => 3,
        "start_date" => activity1_start_time,
        "end_date" => activity1_end_time
      })

      # Activity: 11:20pm - 12:00am
      activity2_start_time = get_utc_date(~N[2023-03-13T23:20:00Z], user.timezone)
      activity2_end_time = get_utc_date(~N[2023-03-14T00:00:00Z], user.timezone)

      Factory.create_activity(user.id, %{
        "timezone" => user.timezone,
        "employer" => "uber",
        "duration" => 1200,
        "distance" => "60",
        "earning_type" => "work",
        "status" => "completed",
        "num_tasks" => 3,
        "start_date" => activity2_start_time,
        "end_date" => activity2_end_time
      })

      timespans =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-13],
          "user_facing"
        )

      timespan = Enum.at(timespans, 0)

      # 11:00 - 11:15     2mile/min                                 = 30
      # 11:15 - 11:20     unknown
      # 11:20 - 12:00     1.5mile/min                               = 60
      assert timespan.platform_miles_quality_percent == 0.917
      assert_in_delta(timespan.platform_miles, 98, 1)
      assert timespan.platform_miles_deduction_cents == 6431
      assert timespan.platform_miles_engaged == 90.0
      assert timespan.platform_miles_deduction_cents_engaged == 5895
    end

    test "Selects Device Mileage when device_quality > 75%" do
      user =
        Factory.create_user(%{
          timezone: "America/Los_Angeles"
        })

      shift_start_time = get_utc_date(~N[2023-03-14T23:15:00Z], user.timezone)
      shift_end_time = get_utc_date(~N[2023-03-14T23:45:00Z], user.timezone)

      Factory.create_shift(%{
        user_id: user.id,
        start_time: shift_start_time,
        end_time: shift_end_time
      })

      activity1_start_time = get_utc_date(~N[2023-03-14T23:20:00Z], user.timezone)
      activity1_end_time = get_utc_date(~N[2023-03-14T23:30:00Z], user.timezone)

      Factory.create_activity(user.id, %{
        "timezone" => user.timezone,
        "employer" => "uber",
        "duration" => 1200,
        "distance" => "10.3",
        "earning_type" => "work",
        "status" => "completed",
        "num_tasks" => 3,
        "start_date" => activity1_start_time,
        "end_date" => activity1_end_time
      })

      create_points(user.id, shift_start_time, shift_end_time, 8)

      timespans =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-14],
          "user_facing"
        )

      timespan = Enum.at(timespans, 0)

      # 80% samples over 100% of the time should be 80% quality
      assert_in_delta(timespan.device_miles_quality_percent, 0.8, 0.05)
      assert timespan.platform_miles_quality_percent > 0
      assert timespan.device_miles == timespan.selected_miles
      assert timespan.device_miles_engaged == timespan.selected_miles_engaged
      assert timespan.device_miles_deduction_cents == timespan.selected_miles_deduction_cents

      assert timespan.device_miles_deduction_cents_engaged ==
               timespan.selected_miles_deduction_cents_engaged
    end

    test "Selects Device Mileage when platform mileage is missing" do
      user =
        Factory.create_user(%{
          timezone: "America/Los_Angeles"
        })

      shift_start_time = get_utc_date(~N[2023-03-14T23:15:00Z], user.timezone)
      shift_end_time = get_utc_date(~N[2023-03-14T23:45:00Z], user.timezone)

      Factory.create_shift(%{
        user_id: user.id,
        start_time: shift_start_time,
        end_time: shift_end_time
      })

      activity1_start_time = get_utc_date(~N[2023-03-14T23:20:00Z], user.timezone)
      activity1_end_time = get_utc_date(~N[2023-03-14T23:30:00Z], user.timezone)

      Factory.create_activity(user.id, %{
        "timezone" => user.timezone,
        "employer" => "uber",
        "duration" => 1200,
        "earning_type" => "work",
        "status" => "completed",
        "num_tasks" => 3,
        "start_date" => activity1_start_time,
        "end_date" => activity1_end_time
      })

      create_points(user.id, shift_start_time, shift_end_time, 8)

      timespans =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-14],
          "user_facing"
        )

      timespan = Enum.at(timespans, 0)

      # 80% samples over 100% of the time should be 80% quality
      assert_in_delta(timespan.device_miles_quality_percent, 0.8, 0.05)
      assert timespan.device_miles == timespan.selected_miles
      assert timespan.device_miles_engaged == timespan.selected_miles_engaged
      assert timespan.device_miles_deduction_cents == timespan.selected_miles_deduction_cents

      assert timespan.device_miles_deduction_cents_engaged ==
               timespan.selected_miles_deduction_cents_engaged
    end

    test "Selects Platform Mileage when device mileage is missing" do
      user =
        Factory.create_user(%{
          timezone: "America/Los_Angeles"
        })

      shift_start_time = get_utc_date(~N[2023-03-14T23:15:00Z], user.timezone)
      shift_end_time = get_utc_date(~N[2023-03-14T23:45:00Z], user.timezone)

      Factory.create_shift(%{
        user_id: user.id,
        start_time: shift_start_time,
        end_time: shift_end_time
      })

      activity1_start_time = get_utc_date(~N[2023-03-14T23:20:00Z], user.timezone)
      activity1_end_time = get_utc_date(~N[2023-03-14T23:30:00Z], user.timezone)

      Factory.create_activity(user.id, %{
        "timezone" => user.timezone,
        "employer" => "uber",
        "duration" => 1200,
        "distance" => "10.3",
        "earning_type" => "work",
        "status" => "completed",
        "num_tasks" => 3,
        "start_date" => activity1_start_time,
        "end_date" => activity1_end_time
      })

      timespans =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-14],
          "user_facing"
        )

      timespan = Enum.at(timespans, 0)

      # 80% samples over 100% of the time should be 80% quality
      assert timespan.platform_miles_quality_percent > 0
      assert timespan.platform_miles == timespan.selected_miles
      assert timespan.platform_miles_engaged == timespan.selected_miles_engaged
      assert timespan.platform_miles_deduction_cents == timespan.selected_miles_deduction_cents

      assert timespan.platform_miles_deduction_cents_engaged ==
               timespan.selected_miles_deduction_cents_engaged
    end

    test "Selects Average of Device and Platform when both are present and quality is within 25%" do
      user =
        Factory.create_user(%{
          timezone: "America/Los_Angeles"
        })

      shift_start_time = get_utc_date(~N[2023-03-14T23:15:00Z], user.timezone)
      shift_end_time = get_utc_date(~N[2023-03-14T23:45:00Z], user.timezone)

      Factory.create_shift(%{
        user_id: user.id,
        start_time: shift_start_time,
        end_time: shift_end_time
      })

      activity1_start_time = get_utc_date(~N[2023-03-14T23:30:00Z], user.timezone)
      activity1_end_time = get_utc_date(~N[2023-03-14T23:45:00Z], user.timezone)

      # 50% quality - platform
      Factory.create_activity(user.id, %{
        "timezone" => user.timezone,
        "employer" => "uber",
        "duration" => 1200,
        "distance" => "10.3",
        "earning_type" => "work",
        "status" => "completed",
        "num_tasks" => 3,
        "start_date" => activity1_start_time,
        "end_date" => activity1_end_time
      })

      # 60% Quality - device
      create_points(user.id, shift_start_time, shift_end_time, 6)

      timespans =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-14],
          "user_facing"
        )

      timespan = Enum.at(timespans, 0)

      assert_in_delta(timespan.device_miles_quality_percent, 0.6, 0.1)
      assert timespan.platform_miles_quality_percent == 0.5

      assert (timespan.device_miles + timespan.platform_miles) / 2 == timespan.selected_miles

      assert (timespan.device_miles_engaged + timespan.platform_miles_engaged) / 2 ==
               timespan.selected_miles_engaged

      assert (timespan.device_miles_deduction_cents + timespan.platform_miles_deduction_cents) / 2 ==
               timespan.selected_miles_deduction_cents

      assert (timespan.device_miles_deduction_cents_engaged +
                timespan.platform_miles_deduction_cents_engaged) / 2 ==
               timespan.selected_miles_deduction_cents_engaged
    end

    test "Selects Device Mileage when both are present and device is more than 25% better than platform" do
      user =
        Factory.create_user(%{
          timezone: "America/Los_Angeles"
        })

      shift_start_time = get_utc_date(~N[2023-03-14T23:15:00Z], user.timezone)
      shift_end_time = get_utc_date(~N[2023-03-14T23:45:00Z], user.timezone)

      Factory.create_shift(%{
        user_id: user.id,
        start_time: shift_start_time,
        end_time: shift_end_time
      })

      activity1_start_time = get_utc_date(~N[2023-03-14T23:30:00Z], user.timezone)
      activity1_end_time = get_utc_date(~N[2023-03-14T23:45:00Z], user.timezone)

      # 50% quality - platform
      Factory.create_activity(user.id, %{
        "timezone" => user.timezone,
        "employer" => "uber",
        "duration" => 1200,
        "distance" => "10.3",
        "earning_type" => "work",
        "status" => "completed",
        "num_tasks" => 3,
        "start_date" => activity1_start_time,
        "end_date" => activity1_end_time
      })

      # 60% Quality - device
      create_points(user.id, shift_start_time, shift_end_time, 9)

      timespans =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-14],
          "user_facing"
        )

      timespan = Enum.at(timespans, 0)

      assert_in_delta(timespan.device_miles_quality_percent, 0.9, 0.05)
      assert timespan.platform_miles_quality_percent == 0.5
      assert timespan.device_miles == timespan.selected_miles
      assert timespan.device_miles_engaged == timespan.selected_miles_engaged
      assert timespan.device_miles_deduction_cents == timespan.selected_miles_deduction_cents

      assert timespan.device_miles_deduction_cents_engaged ==
               timespan.selected_miles_deduction_cents_engaged
    end

    test "Selects Platform Mileage when both are present and platform is more than 25% better than device" do
      user =
        Factory.create_user(%{
          timezone: "America/Los_Angeles"
        })

      shift_start_time = get_utc_date(~N[2023-03-14T23:15:00Z], user.timezone)
      shift_end_time = get_utc_date(~N[2023-03-14T23:45:00Z], user.timezone)

      Factory.create_shift(%{
        user_id: user.id,
        start_time: shift_start_time,
        end_time: shift_end_time
      })

      activity1_start_time = get_utc_date(~N[2023-03-14T23:15:00Z], user.timezone)
      activity1_end_time = get_utc_date(~N[2023-03-14T23:45:00Z], user.timezone)

      # 100% quality - platform
      Factory.create_activity(user.id, %{
        "timezone" => user.timezone,
        "employer" => "uber",
        "duration" => 1200,
        "distance" => "10.3",
        "earning_type" => "work",
        "status" => "completed",
        "num_tasks" => 3,
        "start_date" => activity1_start_time,
        "end_date" => activity1_end_time
      })

      # 60% Quality - device
      create_points(user.id, shift_start_time, shift_end_time, 6)

      timespans =
        Earnings.calculate_timespans_and_allocations_for_user_workday(
          user,
          ~D[2023-03-14],
          "user_facing"
        )

      timespan = Enum.at(timespans, 0)

      assert_in_delta(timespan.device_miles_quality_percent, 0.6, 0.05)
      assert timespan.platform_miles_quality_percent == 1.0
      assert timespan.platform_miles == timespan.selected_miles
      assert timespan.platform_miles_engaged == timespan.selected_miles_engaged
      assert timespan.platform_miles_deduction_cents == timespan.selected_miles_deduction_cents

      assert timespan.platform_miles_deduction_cents_engaged ==
               timespan.selected_miles_deduction_cents_engaged
    end
  end

  describe "Save changes" do
    test "basic function" do
      user =
        Factory.create_user(%{
          timezone: "America/Los_Angeles"
        })

      # Shift: 12:15pm - 4:15pm
      shift_start_time = get_utc_date(~N[2023-03-14T12:15:00Z], user.timezone)
      shift_end_time = get_utc_date(~N[2023-03-14T16:15:00Z], user.timezone)

      shift =
        Factory.create_shift(%{
          user_id: user.id,
          start_time: shift_start_time,
          end_time: shift_end_time
        })

      # Activity: 12:30pm - 2:15pm
      activity_start_time = get_utc_date(~N[2023-03-14T12:30:00Z], user.timezone)
      activity_end_time = get_utc_date(~N[2023-03-14T14:15:00Z], user.timezone)

      activity =
        Factory.create_activity(user.id, %{
          "timezone" => user.timezone,
          "employer" => "uber",
          "duration" => 1200,
          "distance" => "10.3",
          "earning_type" => "work",
          "status" => "completed",
          "num_tasks" => 3,
          "start_date" => activity_start_time,
          "end_date" => activity_end_time
        })

      Earnings.update_timespans_and_allocations_for_user_workday(
        user,
        ~D[2023-03-14],
        "user_facing"
      )

      timespans_0314 =
        Earnings.get_timespans_for_user_workday(user.id, ~D[2023-03-14], "user_facing")

      assert Enum.count(timespans_0314) == 1
      timespan_0314 = Enum.at(timespans_0314, 0)
      assert DateTime.compare(shift_start_time, timespan_0314.start_time) == :eq
      assert DateTime.compare(shift_end_time, timespan_0314.end_time) == :eq
      assert timespan_0314.shift_ids == [shift.id]

      assert Enum.count(timespan_0314.allocations) == 3

      alloc_0 = Enum.at(timespan_0314.allocations, 0)
      assert DateTime.compare(shift_start_time, alloc_0.start_time) == :eq
      assert DateTime.compare(activity_start_time, alloc_0.end_time) == :eq
      assert DateTime.diff(activity_start_time, shift_start_time) == alloc_0.duration_seconds
      assert is_nil(Map.get(alloc_0, :activity_id))
      assert is_nil(Map.get(alloc_0, :activity_coverage_percent))

      alloc_1 = Enum.at(timespan_0314.allocations, 1)
      assert DateTime.compare(activity_start_time, alloc_1.start_time) == :eq
      assert DateTime.compare(activity_end_time, alloc_1.end_time) == :eq
      assert DateTime.diff(activity_end_time, activity_start_time) == alloc_1.duration_seconds
      assert alloc_1.activity_id == activity.id
      assert alloc_1.activity_coverage_percent == Decimal.from_float(1.0)
      assert alloc_1.activity_extends_before == false
      assert alloc_1.activity_extends_after == false

      alloc_2 = Enum.at(timespan_0314.allocations, 2)
      assert DateTime.compare(activity_end_time, alloc_2.start_time) == :eq
      assert DateTime.compare(shift_end_time, alloc_2.end_time) == :eq
      assert DateTime.diff(shift_end_time, activity_end_time) == alloc_2.duration_seconds
      assert is_nil(Map.get(alloc_2, :activity_id))
      assert is_nil(Map.get(alloc_2, :activity_coverage_percent))
    end

    test "supports updates for changed allocations" do
      user =
        Factory.create_user(%{
          timezone: "America/Los_Angeles"
        })

      # Shift: 12:15pm - 4:15pm
      shift_start_time = get_utc_date(~N[2023-03-14T12:15:00Z], user.timezone)
      shift_end_time = get_utc_date(~N[2023-03-14T16:15:00Z], user.timezone)

      shift =
        Factory.create_shift(%{
          user_id: user.id,
          start_time: shift_start_time,
          end_time: shift_end_time
        })

      # Activity: 12:30pm - 2:15pm
      activity_start_time = get_utc_date(~N[2023-03-14T12:30:00Z], user.timezone)
      activity_end_time = get_utc_date(~N[2023-03-14T14:15:00Z], user.timezone)

      activity =
        Factory.create_activity(user.id, %{
          "timezone" => user.timezone,
          "employer" => "uber",
          "duration" => 1200,
          "distance" => "10.3",
          "earning_type" => "work",
          "status" => "completed",
          "num_tasks" => 3,
          "start_date" => activity_start_time,
          "end_date" => activity_end_time
        })

      Earnings.update_timespans_and_allocations_for_user_workday(
        user,
        ~D[2023-03-14],
        "user_facing"
      )

      shift_start_time = get_utc_date(~N[2023-03-14T12:25:00Z], user.timezone)
      shift_end_time = get_utc_date(~N[2023-03-14T14:30:00Z], user.timezone)

      {:ok, shift} =
        Shifts.update_shift(shift, %{
          start_time: shift_start_time,
          end_time: shift_end_time
        })

      Earnings.update_timespans_and_allocations_for_user_workday(
        user,
        ~D[2023-03-14],
        "user_facing"
      )

      timespans_0314 =
        Earnings.get_timespans_for_user_workday(user.id, ~D[2023-03-14], "user_facing")

      assert Enum.count(timespans_0314) == 1
      timespan_0314 = Enum.at(timespans_0314, 0)
      assert DateTime.compare(shift_start_time, timespan_0314.start_time) == :eq
      assert DateTime.compare(shift_end_time, timespan_0314.end_time) == :eq
      assert timespan_0314.shift_ids == [shift.id]

      assert Enum.count(timespan_0314.allocations) == 3

      alloc_0 = Enum.at(timespan_0314.allocations, 0)
      assert DateTime.compare(shift_start_time, alloc_0.start_time) == :eq
      assert DateTime.compare(activity_start_time, alloc_0.end_time) == :eq
      assert DateTime.diff(activity_start_time, shift_start_time) == alloc_0.duration_seconds
      assert is_nil(Map.get(alloc_0, :activity_id))
      assert is_nil(Map.get(alloc_0, :activity_coverage_percent))

      alloc_1 = Enum.at(timespan_0314.allocations, 1)
      assert DateTime.compare(activity_start_time, alloc_1.start_time) == :eq
      assert DateTime.compare(activity_end_time, alloc_1.end_time) == :eq
      assert DateTime.diff(activity_end_time, activity_start_time) == alloc_1.duration_seconds
      assert alloc_1.activity_id == activity.id
      assert alloc_1.activity_coverage_percent == Decimal.from_float(1.0)
      assert alloc_1.activity_extends_before == false
      assert alloc_1.activity_extends_after == false

      alloc_2 = Enum.at(timespan_0314.allocations, 2)
      assert DateTime.compare(activity_end_time, alloc_2.start_time) == :eq
      assert DateTime.compare(shift_end_time, alloc_2.end_time) == :eq
      assert DateTime.diff(shift_end_time, activity_end_time) == alloc_2.duration_seconds
      assert is_nil(Map.get(alloc_2, :activity_id))
      assert is_nil(Map.get(alloc_2, :activity_coverage_percent))
    end

    test "deletes unused allocations" do
      user =
        Factory.create_user(%{
          timezone: "America/Los_Angeles"
        })

      # Shift: 12:15pm - 4:15pm
      shift_start_time = get_utc_date(~N[2023-03-14T12:15:00Z], user.timezone)
      shift_end_time = get_utc_date(~N[2023-03-14T16:15:00Z], user.timezone)

      shift =
        Factory.create_shift(%{
          user_id: user.id,
          start_time: shift_start_time,
          end_time: shift_end_time
        })

      # Activity: 12:30pm - 2:15pm
      activity_start_time = get_utc_date(~N[2023-03-14T12:30:00Z], user.timezone)
      activity_end_time = get_utc_date(~N[2023-03-14T14:15:00Z], user.timezone)

      activity =
        Factory.create_activity(user.id, %{
          "timezone" => user.timezone,
          "employer" => "uber",
          "duration" => 1200,
          "distance" => "10.3",
          "earning_type" => "work",
          "status" => "completed",
          "num_tasks" => 3,
          "start_date" => activity_start_time,
          "end_date" => activity_end_time
        })

      Earnings.update_timespans_and_allocations_for_user_workday(
        user,
        ~D[2023-03-14],
        "user_facing"
      )

      shift_start_time = get_utc_date(~N[2023-03-14T12:30:00Z], user.timezone)
      shift_end_time = get_utc_date(~N[2023-03-14T14:30:00Z], user.timezone)

      {:ok, shift} =
        Shifts.update_shift(shift, %{
          start_time: shift_start_time,
          end_time: shift_end_time
        })

      Earnings.update_timespans_and_allocations_for_user_workday(
        user,
        ~D[2023-03-14],
        "user_facing"
      )

      timespans_0314 =
        Earnings.get_timespans_for_user_workday(user.id, ~D[2023-03-14], "user_facing")

      assert Enum.count(timespans_0314) == 1
      timespan_0314 = Enum.at(timespans_0314, 0)
      assert DateTime.compare(shift_start_time, timespan_0314.start_time) == :eq
      assert DateTime.compare(shift_end_time, timespan_0314.end_time) == :eq
      assert timespan_0314.shift_ids == [shift.id]

      assert Enum.count(timespan_0314.allocations) == 2

      alloc_0 = Enum.at(timespan_0314.allocations, 0)
      assert DateTime.compare(activity_start_time, alloc_0.start_time) == :eq
      assert DateTime.compare(activity_end_time, alloc_0.end_time) == :eq
      assert DateTime.diff(activity_end_time, activity_start_time) == alloc_0.duration_seconds
      assert alloc_0.activity_id == activity.id
      assert alloc_0.activity_coverage_percent == Decimal.from_float(1.0)
      assert alloc_0.activity_extends_before == false
      assert alloc_0.activity_extends_after == false

      alloc_1 = Enum.at(timespan_0314.allocations, 1)
      assert DateTime.compare(activity_end_time, alloc_1.start_time) == :eq
      assert DateTime.compare(shift_end_time, alloc_1.end_time) == :eq
      assert DateTime.diff(shift_end_time, activity_end_time) == alloc_1.duration_seconds
      assert is_nil(Map.get(alloc_1, :activity_id))
      assert is_nil(Map.get(alloc_1, :activity_coverage_percent))
    end
  end

  defp get_utc_date(%NaiveDateTime{} = local_dtm, timezone) do
    DateTime.from_naive!(local_dtm, timezone)
    |> DateTime.shift_zone!("Etc/UTC")
  end

  defp create_points(user_id, start_time, end_time, coverage_level)
       when is_integer(coverage_level) and coverage_level < 10 and coverage_level > 0 do
    time_windows = Enum.to_list(DateTime.to_unix(start_time)..DateTime.to_unix(end_time)//10)

    _ =
      Enum.reduce(time_windows, [35.512230, -122.658722, 0], fn dtm, [lat, lon, idx] ->
        if rem(idx, 10) < coverage_level do
          Factory.create_point(%{
            user_id: user_id,
            latitude: lat,
            longitude: lon,
            recorded_at: DateTime.from_unix!(dtm)
          })
        end

        [lat + 0.00002, lon + 0.00002, idx + 1]
      end)

    Earnings.estimate_device_mileage_for_time_range(user_id, start_time, end_time)
  end
end
