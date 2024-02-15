defmodule DriversSeatCoop.Util.DateTimeUtil do
  @moduledoc """
  This module contains helper functions for working with dates and times
  """

  @working_day_end_time ~T[04:00:00]

  @doc """
  Given a from_date (with time zone), day_of_week_number (sunday=0), time_of_day, identify the next occurrence
  of that day and time after the from_date in the time zone supplied
  For example:  What is the next Tuesday, 2pm, after 3/2/2022 1:00am PST in PST?
  """
  def get_next_occurrence_after_date(from_timestamp, day_of_week_number, time_of_day)
      when day_of_week_number >= 0 and day_of_week_number <= 6 do
    timezone = from_timestamp.time_zone

    # truncate the from_timestamp to the date
    from_date = DateTime.to_date(from_timestamp)
    from_time = DateTime.to_time(from_timestamp)

    # roll back to start of week with Sunday as the start
    start_week_date = Date.beginning_of_week(from_date, :sunday)

    # add number day of week days to the start of week
    target_date = Date.add(start_week_date, day_of_week_number)

    # If the result is before the from_date, add a week
    target_date =
      if Date.compare(target_date, from_date) == :lt or
           (Date.compare(target_date, from_date) == :eq and
              Time.compare(time_of_day, from_time) == :lt) do
        Date.add(target_date, 7)
      else
        target_date
      end

    case DateTime.new(target_date, time_of_day, timezone) do
      {:ok, next} -> next
      {:gap, _before_gap, after_gap} -> after_gap
      {:ambiguous, first_date, _second_date} -> first_date
    end
  end

  @doc """
  Given a day_of_week_number (sunday=0), time_of_day, and a timezone, identify the next occurrence
  of that day and time in the future in the time zone supplied
  For example:  What is the next Tuesday, 2pm PST as a PST date time?
  """
  def get_next_occurrence(day_of_week_number, time_of_day, timezone)
      when day_of_week_number >= 0 and day_of_week_number <= 6 do
    {:ok, now_local} = DateTime.now(timezone)

    get_next_occurrence_after_date(now_local, day_of_week_number, time_of_day)
  end

  @doc """
  Given a day_of_week_number (sunday=0), time_of_day, and a timezone, identify the next occurrence
  of that day and time in the future in the time zone supplied
  For example:  What is the next Tuesday, 2pm PST as a PST date time?
  """
  def get_next_occurrence_in_utc(day_of_week_number, time_of_day, timezone)
      when day_of_week_number >= 0 and day_of_week_number <= 6 do
    {:ok, now_local} = DateTime.now(timezone)

    next_occurrence_local =
      get_next_occurrence_after_date(now_local, day_of_week_number, time_of_day)

    DateTime.shift_zone!(next_occurrence_local, "Etc/UTC")
  end

  @doc """
  Given a day of week (sunday=0), time of day, and number of minutes to increment, return
  the new time of day and day of week
  """
  def increment_minutes(day_of_week_number, time_of_day, duration_minutes)
      when duration_minutes >= 0
      when day_of_week_number >= 0 and day_of_week_number <= 6 do
    # 1970-01-04 was a sunday (day_of_week_number=0), the end of the week. add
    # days to get to the correct day_of_week_number then add minutes to reach
    # the desired increment
    datetime =
      Date.add(~D[1970-01-04], day_of_week_number)
      |> DateTime.new!(time_of_day)
      |> DateTime.add(duration_minutes * 60, :second)

    # NOTE: this utility module treats sunday as the 0th day of the week, while
    # elixir treats it as the 7th day of the week. we use rem to correct for
    # that
    %{
      day_of_week_number: rem(Date.day_of_week(datetime), 7),
      time_of_day: DateTime.to_time(datetime)
    }
  end

  def floor_minute(nil) do
    nil
  end

  def floor_minute(datetime) do
    datetime
    |> DateTime.truncate(:second)
    |> Map.put(:second, 0)
  end

  def ceiling_minute(nil) do
    nil
  end

  def ceiling_minute(datetime) do
    floor = floor_minute(datetime)

    if DateTime.compare(floor, datetime) == :eq do
      datetime
    else
      DateTime.add(floor, 1, :minute)
    end
  end

  def is_between(nil, _start_date, _end_date) do
    false
  end

  def is_between(_test_date, nil, nil) do
    false
  end

  def is_between(test_date, start_date, nil) do
    case DateTime.compare(test_date, start_date) do
      :lt -> false
      _ -> true
    end
  end

  def is_between(test_date, nil, end_date) do
    case DateTime.compare(test_date, end_date) do
      :gt -> false
      _ -> true
    end
  end

  def is_between(test_date, start_date, end_date) do
    is_between(test_date, start_date, nil) and is_between(test_date, nil, end_date)
  end

  def working_day_bounds(date, timezone) do
    # WARN: this can fail on certain ambigious times due to DST and we don't
    # have a way to handle that yet
    beginning =
      date
      |> DateTime.new!(@working_day_end_time, timezone)
      |> DateTime.shift_zone!("Etc/UTC")

    ending =
      Date.add(date, 1)
      |> DateTime.new!(@working_day_end_time, timezone)
      |> DateTime.shift_zone!("Etc/UTC")

    [beginning, ending]
  end

  def datetime_to_working_day(nil, _timezone), do: nil

  def datetime_to_working_day(%DateTime{} = datetime, timezone) do
    shifted_datetime =
      datetime
      |> DateTime.shift_zone!(timezone)

    date = DateTime.to_date(shifted_datetime)
    time = DateTime.to_time(shifted_datetime)

    if Time.compare(time, @working_day_end_time) == :lt do
      date |> Date.add(-1)
    else
      date
    end
  end

  def get_time_window_for_date(%Date{} = date, frequency) do
    get_time_windows_for_range(date, date, frequency)
    |> Enum.at(0)
  end

  def get_time_windows_for_range(%Date{} = start_date, %Date{} = end_date, :day = _frequency) do
    Date.range(start_date, end_date)
    |> Enum.map(fn date -> {date, date} end)
  end

  def get_time_windows_for_range(%Date{} = start_date, %Date{} = end_date, :week = _frequency) do
    start_date = Date.beginning_of_week(start_date, :monday)
    end_date = Date.beginning_of_week(end_date, :monday)

    Date.range(start_date, end_date, 7)
    |> Enum.map(fn date -> {date, Date.add(date, 6)} end)
  end

  def get_time_windows_for_range(%Date{} = start_date, %Date{} = end_date, :month = _frequency) do
    start_date = Date.beginning_of_month(start_date)
    end_date = Date.beginning_of_month(end_date)

    get_time_window_for_range_month(start_date, end_date)
  end

  def get_time_windows_for_range(%Date{} = start_date, %Date{} = end_date, :year = _frequency) do
    Range.new(start_date.year, end_date.year)
    |> Enum.map(fn y -> {Date.new!(y, 1, 1), Date.new!(y, 12, 31)} end)
  end

  def get_time_windows_for_range(%Date{} = start_date, %Date{} = end_date, frequency),
    do: get_time_windows_for_range(start_date, end_date, String.to_atom(frequency))

  defp get_time_window_for_range_month(start_date, end_date) do
    end_of_month = Date.end_of_month(start_date)
    result = [{start_date, end_of_month}]

    start_date = Date.add(end_of_month, 1)

    if Date.compare(start_date, end_date) == :gt do
      result
    else
      result ++ get_time_windows_for_range(start_date, end_date, :month)
    end
  end

  @doc """
  This is the index that DSC uses for day of week
  Sunday = 0, Saturday = 6
  """
  def day_index(%Date{} = date) do
    Date.day_of_week(date, :sunday) - 1
  end

  def day_index(%DateTime{} = date) do
    day_index(DateTime.to_date(date))
  end

  def day_index(%NaiveDateTime{} = date) do
    day_index(NaiveDateTime.to_date(date))
  end
end
