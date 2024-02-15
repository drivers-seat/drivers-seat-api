defmodule DriversSeatCoop.DateTimeUtilTest do
  use DriversSeatCoop.DataCase
  alias DateTime
  alias DriversSeatCoop.Util.DateTimeUtil

  describe "get_next_occurrence_after_date tests" do
    test "get_next_occurrence_after_date/3 returns future date when target day/time is in the future" do
      expected = DateTime.new!(~D[2022-09-07], ~T[14:00:00], "America/Los_Angeles")

      actual =
        DateTimeUtil.get_next_occurrence_after_date(
          DateTime.new!(~D[2022-09-06], ~T[16:00:00], "America/Los_Angeles"),
          3,
          ~T[14:00:00]
        )

      assert expected == actual
    end

    test "get_next_occurrence_after_date/3 returns future date when target day/time is in the past" do
      expected = DateTime.new!(~D[2022-03-16], ~T[14:00:00], "America/Los_Angeles")

      actual =
        DateTimeUtil.get_next_occurrence_after_date(
          DateTime.new!(~D[2022-03-11], ~T[16:00:00], "America/Los_Angeles"),
          3,
          ~T[14:00:00]
        )

      assert expected == actual
    end

    test "get_next_occurrence_after_date/3 works with Daylight savings time start" do
      expected = DateTime.new!(~D[2022-09-12], ~T[14:00:00], "America/Los_Angeles")

      actual =
        DateTimeUtil.get_next_occurrence_after_date(
          DateTime.new!(~D[2022-09-06], ~T[16:00:00], "America/Los_Angeles"),
          1,
          ~T[14:00:00]
        )

      assert expected == actual
    end

    test "get_next_occurrence_after_date/3 works with Daylight savings time start where result falls in gap" do
      expected = DateTime.new!(~D[2022-03-13], ~T[03:00:00], "America/Los_Angeles")

      actual =
        DateTimeUtil.get_next_occurrence_after_date(
          DateTime.new!(~D[2022-03-13], ~T[01:00:00], "America/Los_Angeles"),
          0,
          ~T[02:30:00]
        )

      assert expected == actual
    end

    test "get_next_occurrence_after_date/3 works with Daylight savings time end" do
      expected = DateTime.new!(~D[2022-11-09], ~T[14:00:00], "America/Los_Angeles")

      actual =
        DateTimeUtil.get_next_occurrence_after_date(
          DateTime.new!(~D[2022-11-04], ~T[16:00:00], "America/Los_Angeles"),
          3,
          ~T[14:00:00]
        )

      assert expected == actual
    end

    test "get_next_occurrence_after_date/3 works with Daylight savings time end where result is ambiguous because it overlaps" do
      {:ambiguous, expected, _second} =
        DateTime.new(~D[2022-11-06], ~T[01:30:00], "America/Los_Angeles")

      actual =
        DateTimeUtil.get_next_occurrence_after_date(
          DateTime.new!(~D[2022-11-06], ~T[00:30:00], "America/Los_Angeles"),
          0,
          ~T[01:30:00]
        )

      assert expected == actual
    end
  end

  describe "get_next_occurrence tests" do
    test "get_next_occurrence/3 always returns a future date when target is in the future" do
      now = DateTime.now!("America/Phoenix")

      now_plus3hr = DateTime.add(now, 60 * 60 * 3, :second)
      now_plus3hr_dt = DateTime.to_date(now_plus3hr)
      now_plus3hr_tm = DateTime.to_time(now_plus3hr)
      now_plus3hr_day_of_week = Date.day_of_week(now_plus3hr_dt, :sunday) - 1

      actual =
        DateTimeUtil.get_next_occurrence(
          now_plus3hr_day_of_week,
          now_plus3hr_tm,
          now_plus3hr.time_zone
        )

      assert DateTime.compare(actual, now) == :gt
      assert DateTime.to_time(actual) == now_plus3hr_tm
      assert actual.time_zone == now.time_zone
      assert Date.day_of_week(actual, :sunday) - 1 == now_plus3hr_day_of_week
    end

    test "get_next_occurrence/3 always returns a future date when target is in the past" do
      now = DateTime.now!("America/Phoenix")

      now_plus3hr = DateTime.add(now, -60 * 60 * 3, :second)
      now_plus3hr_dt = DateTime.to_date(now_plus3hr)
      now_plus3hr_tm = DateTime.to_time(now_plus3hr)
      now_plus3hr_day_of_week = Date.day_of_week(now_plus3hr_dt, :sunday) - 1

      actual =
        DateTimeUtil.get_next_occurrence(
          now_plus3hr_day_of_week,
          now_plus3hr_tm,
          now_plus3hr.time_zone
        )

      assert DateTime.compare(actual, now) == :gt
      assert DateTime.to_time(actual) == now_plus3hr_tm
      assert actual.time_zone == now.time_zone
      assert Date.day_of_week(actual, :sunday) - 1 == now_plus3hr_day_of_week
    end

    test "get_next_occurrence_in_utc/3 returns correct utc time" do
      now = DateTime.now!("America/Phoenix")

      now_plus3hr = DateTime.add(now, -60 * 60 * 3, :second)
      now_plus3hr_dt = DateTime.to_date(now_plus3hr)
      now_plus3hr_tm = DateTime.to_time(now_plus3hr)
      now_plus3hr_day_of_week = Date.day_of_week(now_plus3hr_dt, :sunday) - 1

      expected_local =
        DateTimeUtil.get_next_occurrence(
          now_plus3hr_day_of_week,
          now_plus3hr_tm,
          now_plus3hr.time_zone
        )

      expected = DateTime.shift_zone!(expected_local, "Etc/UTC")

      actual =
        DateTimeUtil.get_next_occurrence_in_utc(
          now_plus3hr_day_of_week,
          now_plus3hr_tm,
          now_plus3hr.time_zone
        )

      assert expected == actual
    end
  end

  describe "increment_minutes tests" do
    test "increment_minutes/3 returns correct value when value within same day" do
      time_of_day = ~T[14:40:00.000000]
      day_of_week = 1
      duration_minutes = 160

      expected = %{
        day_of_week_number: 1,
        time_of_day: Time.add(time_of_day, duration_minutes * 60, :second)
      }

      actual = DateTimeUtil.increment_minutes(day_of_week, time_of_day, duration_minutes)

      assert expected == actual
    end

    test "increment_minutes/3 returns correct value when transitions to next day but less than 24-hours" do
      time_of_day = ~T[23:40:00.000000]
      day_of_week = 1
      duration_minutes = 160

      expected = %{
        day_of_week_number: 2,
        time_of_day: Time.add(time_of_day, duration_minutes * 60, :second)
      }

      actual = DateTimeUtil.increment_minutes(day_of_week, time_of_day, duration_minutes)

      assert expected == actual
    end

    test "increment_minutes/3 returns correct value when transitions to next day and more than 24-hours" do
      time_of_day = ~T[20:40:00.000000000]
      day_of_week = 1
      duration_minutes = 1600

      expected = %{
        day_of_week_number: 2,
        time_of_day: Time.add(time_of_day, duration_minutes * 60, :second)
      }

      actual = DateTimeUtil.increment_minutes(day_of_week, time_of_day, duration_minutes)

      assert expected == actual
    end

    test "increment_minutes/3 returns correct value when transitions to next week" do
      time_of_day = ~T[22:40:00.000000]
      day_of_week = 6
      duration_minutes = 1600

      expected = %{
        day_of_week_number: 1,
        time_of_day: Time.add(time_of_day, duration_minutes * 60, :second)
      }

      actual = DateTimeUtil.increment_minutes(day_of_week, time_of_day, duration_minutes)

      assert expected == actual
    end

    test "increment_minutes/3 returns correct value when increment 0" do
      time_of_day = ~T[22:40:00.000000]
      day_of_week = 6
      duration_minutes = 0

      expected = %{
        day_of_week_number: 6,
        time_of_day: time_of_day
      }

      actual = DateTimeUtil.increment_minutes(day_of_week, time_of_day, duration_minutes)

      assert expected == actual
    end

    test "increment_minutes/3 returns correct value when increment exactly 24 hours" do
      time_of_day = ~T[22:40:00.000000]
      day_of_week = 4
      duration_minutes = 1440

      expected = %{
        day_of_week_number: 5,
        time_of_day: time_of_day
      }

      actual = DateTimeUtil.increment_minutes(day_of_week, time_of_day, duration_minutes)

      assert expected == actual
    end
  end

  describe "floor, ceiling, and between tests" do
    test "floor_minute always rounds down" do
      datetime_1 = ~U[2023-02-28 17:35:46.604565Z]
      datetime_2 = ~U[2023-02-28 17:35:00.604565Z]
      datetime_3 = ~U[2023-02-28 17:35:46.000000Z]
      datetime_4 = ~U[2023-02-28 17:35:00.000000Z]

      expected = ~U[2023-02-28 17:35:00.000000Z]

      assert DateTime.compare(DateTimeUtil.floor_minute(datetime_1), expected) == :eq
      assert DateTime.compare(DateTimeUtil.floor_minute(datetime_2), expected) == :eq
      assert DateTime.compare(DateTimeUtil.floor_minute(datetime_3), expected) == :eq
      assert DateTime.compare(DateTimeUtil.floor_minute(datetime_4), expected) == :eq
    end

    test "ceiling_minute always rounds up" do
      datetime_1 = ~U[2023-02-28 17:35:46.604565Z]
      datetime_2 = ~U[2023-02-28 17:35:00.604565Z]
      datetime_3 = ~U[2023-02-28 17:35:46.000000Z]
      datetime_4 = ~U[2023-02-28 17:35:00.000000Z]

      expected = ~U[2023-02-28 17:36:00.000000Z]
      expected_4 = ~U[2023-02-28 17:35:00.000000Z]

      assert DateTime.compare(DateTimeUtil.ceiling_minute(datetime_1), expected) == :eq
      assert DateTime.compare(DateTimeUtil.ceiling_minute(datetime_2), expected) == :eq
      assert DateTime.compare(DateTimeUtil.ceiling_minute(datetime_3), expected) == :eq

      # Don't add minute if the supplied time is on the minute
      assert DateTime.compare(DateTimeUtil.ceiling_minute(datetime_4), expected_4) == :eq
    end

    test "is_between" do
      datetime_1 = ~U[2023-02-28 08:35:46.604565Z]
      datetime_2 = ~U[2023-02-28 10:35:52.604565Z]
      datetime_3 = ~U[2023-02-28 11:35:52.604565Z]

      assert not DateTimeUtil.is_between(nil, datetime_1, datetime_2)
      assert not DateTimeUtil.is_between(datetime_1, nil, nil)

      assert not DateTimeUtil.is_between(datetime_1, ~U[2023-02-28 10:35:52.604565Z], nil)
      assert not DateTimeUtil.is_between(datetime_1, datetime_2, nil)
      assert DateTimeUtil.is_between(datetime_2, datetime_1, nil)

      assert DateTimeUtil.is_between(datetime_1, nil, datetime_2)
      assert not DateTimeUtil.is_between(datetime_2, nil, datetime_1)

      assert DateTimeUtil.is_between(datetime_2, datetime_1, datetime_3)
      assert not DateTimeUtil.is_between(datetime_1, datetime_2, datetime_3)
      assert not DateTimeUtil.is_between(datetime_3, datetime_1, datetime_2)
    end
  end

  describe "get_time_window_for_date tests" do
    test "day" do
      date = ~D[2023-05-24]

      {start_date, end_date} = DateTimeUtil.get_time_window_for_date(date, :day)

      assert start_date == date
      assert end_date == date
    end

    test "month starts on 1st day of month" do
      date = ~D[2023-05-24]

      {start_date, end_date} = DateTimeUtil.get_time_window_for_date(date, :month)

      assert start_date == ~D[2023-05-01]
      assert end_date == ~D[2023-05-31]
    end

    test "week starts on Monday" do
      date = ~D[2023-05-24]

      {start_date, end_date} = DateTimeUtil.get_time_window_for_date(date, :week)

      assert start_date == ~D[2023-05-22]
      assert end_date == ~D[2023-05-28]
    end

    test "week starts on Monday and does not roll back given a monday" do
      date = ~D[2023-05-22]

      {start_date, end_date} = DateTimeUtil.get_time_window_for_date(date, :week)

      assert start_date == ~D[2023-05-22]
      assert end_date == ~D[2023-05-28]
    end
  end

  describe "get_time_windows_for_range tests" do
    test "day" do
      start_date = ~D[2023-05-24]
      end_date = ~D[2023-05-25]

      result = DateTimeUtil.get_time_windows_for_range(start_date, end_date, :day)

      assert result == [
               {start_date, start_date},
               {end_date, end_date}
             ]
    end

    test "week - values in same week return a single entry" do
      start_date = ~D[2023-05-24]
      end_date = ~D[2023-05-25]

      result = DateTimeUtil.get_time_windows_for_range(start_date, end_date, :week)

      assert result == [
               {~D[2023-05-22], ~D[2023-05-28]}
             ]
    end

    test "week" do
      start_date = ~D[2023-05-24]
      end_date = ~D[2023-05-29]

      result = DateTimeUtil.get_time_windows_for_range(start_date, end_date, :week)

      assert result == [
               {~D[2023-05-22], ~D[2023-05-28]},
               {~D[2023-05-29], ~D[2023-06-04]}
             ]
    end

    test "month - values in same month return single entry" do
      start_date = ~D[2023-05-24]
      end_date = ~D[2023-05-29]

      result = DateTimeUtil.get_time_windows_for_range(start_date, end_date, :month)

      assert result == [
               {~D[2023-05-01], ~D[2023-05-31]}
             ]
    end
  end
end
