defmodule DriversSeatCoop.Earnings do
  @moduledoc """
  The Earnings context.
  """

  import Ecto.Query, warn: false
  alias DriversSeatCoop.Activities
  alias DriversSeatCoop.Driving.Point
  alias DriversSeatCoop.Earnings.Timespan
  alias DriversSeatCoop.Earnings.TimespanAllocation
  alias DriversSeatCoop.Goals.Oban.CalculatePerformanceForUserWindow
  alias DriversSeatCoop.Irs
  alias DriversSeatCoop.Repo
  alias DriversSeatCoop.Shifts
  alias DriversSeatCoop.Util.DateTimeUtil

  @calc_shift_settings_user_facing %{
    padding_before_minutes: 0,
    padding_after_minutes: 0,
    padding_gap_break_miutes: 10
  }

  @calc_shift_settings_auto_calculated %{
    padding_before_minutes: 10,
    padding_after_minutes: 5,
    padding_gap_break_miutes: 30
  }

  @doc """
  Return detailed timespans and allocations
  """
  def get_timespan_details(user_id, calc_method, work_day_start, work_day_end) do
    qry =
      get_timespans_query(user_id)
      |> filter_timespans_query_calc_method(calc_method)
      |> filter_timespans_query_date_range(work_day_start, work_day_end)

    from(ts in qry,
      preload: [allocations: :activity]
    )
    |> Repo.all()
  end

  @doc """
  Return a summarization of deduplicatd working time and mileage summarized by a time grouping (day, week, month, year)
  """
  def get_overall_time_and_mileage_summary(
        user_id_or_ids,
        calc_method,
        work_date_start,
        work_date_end,
        time_grouping \\ nil
      ) do
    time_miles_qry =
      get_timespans_query(user_id_or_ids)
      |> filter_timespans_query_calc_method(calc_method)
      |> filter_timespans_query_date_range(work_date_start, work_date_end)

    time_miles_qry =
      from(ts in time_miles_qry,
        select: %{
          user_id: ts.user_id,
          count_work_days: fragment("COUNT(DISTINCT ?)", ts.work_date),
          duration_seconds: sum(ts.duration_seconds),
          device_miles: sum(ts.device_miles),
          device_miles_deduction_cents: sum(ts.device_miles_deduction_cents),
          duration_seconds_engaged: sum(ts.duration_seconds_engaged),
          device_miles_engaged: sum(ts.device_miles_engaged),
          device_miles_deduction_cents_engaged: sum(ts.device_miles_deduction_cents_engaged),
          device_miles_quality_percent:
            fragment(
              "CASE WHEN SUM(COALESCE(?,0)) = 0 THEN NULL ELSE SUM(? * COALESCE(?,0))/SUM(COALESCE(?,0)) END",
              ts.duration_seconds,
              ts.duration_seconds,
              ts.device_miles_quality_percent,
              ts.duration_seconds
            ),
          platform_miles: sum(ts.platform_miles),
          platform_miles_deduction_cents: sum(ts.platform_miles_deduction_cents),
          platform_miles_engaged: sum(ts.platform_miles_engaged),
          platform_miles_deduction_cents_engaged: sum(ts.platform_miles_deduction_cents_engaged),
          platform_miles_quality_percent:
            fragment(
              "CASE WHEN SUM(COALESCE(?,0)) = 0 THEN NULL ELSE SUM(? * COALESCE(?,0))/SUM(COALESCE(?,0)) END",
              ts.duration_seconds,
              ts.duration_seconds,
              ts.platform_miles_quality_percent,
              ts.duration_seconds
            ),
          selected_miles: sum(ts.selected_miles),
          selected_miles_deduction_cents: sum(ts.selected_miles_deduction_cents),
          selected_miles_engaged: sum(ts.selected_miles_engaged),
          selected_miles_deduction_cents_engaged: sum(ts.selected_miles_deduction_cents_engaged),
          selected_miles_quality_percent:
            fragment(
              "CASE WHEN SUM(COALESCE(?,0)) = 0 THEN NULL ELSE SUM(? * COALESCE(?,0))/SUM(COALESCE(?,0)) END",
              ts.duration_seconds,
              ts.duration_seconds,
              ts.selected_miles_quality_percent,
              ts.duration_seconds
            )
        }
      )

    grouping = [:user] ++ List.wrap(time_grouping)

    rollup_timespans(time_miles_qry, grouping)
    |> Repo.all()
  end

  @doc """
  Return a summarization of earnings, work-time, and mileage from grouped by time (day, week, month, year) and by other fields
  Note, in the event of overlapping work, time and mileage information will NOT be deduplicated
  Note, not all earnings are are based on work that have time. (ie incentives would not be included in this)
  """
  def get_job_earnings_summary(
        user_id_or_ids,
        calc_method,
        work_date_start,
        work_date_end,
        time_grouping \\ nil,
        other_groupings \\ nil
      ) do
    work_earnings_qry =
      get_timespans_query(user_id_or_ids)
      |> filter_timespans_query_calc_method(calc_method)
      |> filter_timespans_query_date_range(work_date_start, work_date_end)

    work_earnings_qry =
      from(ts in work_earnings_qry,
        left_join: alloc in assoc(ts, :allocations),
        as: :alloc,
        left_join: activity in assoc(alloc, :activity),
        as: :act,
        select: %{
          user_id: ts.user_id,
          job_count: fragment("SUM(?)::int", alloc.activity_coverage_percent),
          job_count_days: fragment("COUNT(DISTINCT ?)", ts.work_date),
          job_count_tasks:
            fragment("SUM(? * ?)::int", alloc.activity_coverage_percent, activity.tasks_total),
          duration_seconds: sum(alloc.duration_seconds),
          device_miles: sum(alloc.device_miles),
          device_miles_deduction_cents: sum(alloc.device_miles_deduction_cents),
          platform_miles: sum(alloc.platform_miles),
          job_earnings_pay_cents:
            fragment(
              "SUM(? * ?)::int",
              alloc.activity_coverage_percent,
              activity.earnings_pay_cents
            ),
          job_earnings_tip_cents:
            fragment(
              "SUM(? * ?)::int",
              alloc.activity_coverage_percent,
              activity.earnings_tip_cents
            ),
          job_earnings_bonus_cents:
            fragment(
              "SUM(? * ?)::int",
              alloc.activity_coverage_percent,
              activity.earnings_bonus_cents
            ),
          job_earnings_total_cents:
            fragment(
              "SUM(? * ?)::int",
              alloc.activity_coverage_percent,
              activity.earnings_total_cents
            )
        }
      )

    summarize_by = [:user] ++ List.wrap(time_grouping) ++ List.wrap(other_groupings)

    rollup_timespans(work_earnings_qry, summarize_by)
    |> Repo.all()
  end

  defp rollup_timespans(qry, summarize_by) when is_list(summarize_by) do
    summarize_by =
      summarize_by
      |> List.wrap()
      |> Enum.filter(fn x -> not is_nil(x) end)
      |> Enum.map(fn x -> String.to_atom("#{x}") end)
      |> Enum.uniq()

    Enum.reduce(summarize_by, qry, fn field, qry ->
      rollup_timespans(qry, field)
    end)
  end

  # credo:disable-for-next-line
  defp rollup_timespans(qry, field) do
    field = String.to_atom("#{field}")

    case field do
      :user ->
        from(ts in qry,
          select_merge: %{
            user_id: ts.user_id
          },
          group_by: [ts.user_id]
        )

      :day ->
        from(ts in qry,
          select_merge: %{
            day: ts.work_date
          },
          group_by: [ts.work_date]
        )

      :week ->
        from([ts] in qry,
          select_merge: %{
            week: fragment("DATE_TRUNC('week', ?)::date", ts.work_date)
          },
          group_by: [fragment("DATE_TRUNC('week', ?)::date", ts.work_date)]
        )

      :month ->
        from(ts in qry,
          select_merge: %{
            month: fragment("DATE_TRUNC('month', ?)::date", ts.work_date)
          },
          group_by: [fragment("DATE_TRUNC('month', ?)::date", ts.work_date)]
        )

      :quarter ->
        from(ts in qry,
          select_merge: %{
            quarter: fragment("DATE_TRUNC('quarter', ?)::date", ts.work_date)
          },
          group_by: [fragment("DATE_TRUNC('quarter', ?)::date", ts.work_date)]
        )

      :year ->
        from(ts in qry,
          select_merge: %{
            year: fragment("DATE_TRUNC('year', ?)::date", ts.work_date)
          },
          group_by: [fragment("DATE_TRUNC('year', ?)::date", ts.work_date)]
        )

      :employer ->
        qry
        |> select_merge([_ts, _alloc, act], %{employer: act.employer})
        |> group_by([_ts, _alloc, act], [act.employer])

      :employer_service ->
        qry
        |> select_merge([_ts, _alloc, act], %{employer_service: act.employer_service})
        |> group_by([_ts, _alloc, act], [act.employer_service])

      :service_class ->
        qry
        |> select_merge([_ts, _alloc, act], %{service_class: act.service_class})
        |> group_by([_ts, _alloc, act], [act.service_class])

      _ ->
        qry
    end
  end

  @doc """
  Return a query of activities for example, bonuses or incentives
  """
  def get_other_earnings_query(
        user_id_or_ids,
        work_date_start,
        work_date_end
      ) do
    activities_qry =
      Activities.get_activities_query(user_id_or_ids, %{
        work_date_start: work_date_start,
        work_date_end: work_date_end
      })

    from(activity in activities_qry,
      where:
        fragment(
          "COALESCE(?,0) != 0 OR COALESCE(?,0) != 0 OR COALESCE(?,0) != 0 OR COALESCE(?,0) != 0",
          activity.earnings_pay_cents,
          activity.earnings_tip_cents,
          activity.earnings_bonus_cents,
          activity.earnings_total_cents
        ),
      where:
        is_nil(activity.timestamp_work_start) or
          is_nil(activity.timestamp_work_end) or
          activity.timestamp_work_start == activity.timestamp_work_end
    )
  end

  @doc """
  Return a summarization of earnings not associated to work-time,
  for example, bonuses or incentives
  """
  def get_other_earnings_summary(
        user_id,
        work_date_start,
        work_date_end,
        time_grouping \\ nil,
        other_groupings \\ nil
      ) do
    activities_qry =
      from(activity in get_other_earnings_query(user_id, work_date_start, work_date_end),
        select: %{
          user_id: activity.user_id,
          other_count_activities: count(),
          other_count_days:
            fragment(
              "COUNT(DISTINCT COALESCE(?,?))",
              activity.working_day_start,
              activity.working_day_end
            ),
          other_earnings_pay_cents: sum(activity.earnings_pay_cents),
          other_earnings_tip_cents: sum(activity.earnings_tip_cents),
          other_earnings_bonus_cents: sum(activity.earnings_bonus_cents),
          other_earnings_total_cents: sum(activity.earnings_total_cents)
        }
      )

    summarize_by = [:user] ++ List.wrap(time_grouping) ++ List.wrap(other_groupings)

    rollup_activities(activities_qry, summarize_by)
    |> Repo.all()
  end

  defp rollup_activities(qry, summarize_by) when is_list(summarize_by) do
    Enum.reduce(summarize_by, qry, fn field, qry ->
      rollup_activities(qry, field)
    end)
  end

  # credo:disable-for-next-line
  defp rollup_activities(qry, field) do
    field = String.to_atom("#{field}")

    case field do
      :user ->
        from(act in qry,
          select_merge: %{user_id: act.user_id},
          group_by: [act.user_id]
        )

      :day ->
        from(act in qry,
          select_merge: %{
            day: fragment("COALESCE(?,?)", act.working_day_start, act.working_day_end)
          },
          group_by: [fragment("COALESCE(?,?)", act.working_day_start, act.working_day_end)]
        )

      :week ->
        from(act in qry,
          select_merge: %{
            week:
              fragment(
                "DATE_TRUNC('week', COALESCE(?,?))::date",
                act.working_day_start,
                act.working_day_end
              )
          },
          group_by: [
            fragment(
              "DATE_TRUNC('week', COALESCE(?,?))::date",
              act.working_day_start,
              act.working_day_end
            )
          ]
        )

      :month ->
        from(act in qry,
          select_merge: %{
            month:
              fragment(
                "DATE_TRUNC('month', COALESCE(?,?))::date",
                act.working_day_start,
                act.working_day_end
              )
          },
          group_by: [
            fragment(
              "DATE_TRUNC('month', COALESCE(?,?))::date",
              act.working_day_start,
              act.working_day_end
            )
          ]
        )

      :quarter ->
        from(act in qry,
          select_merge: %{
            quarter:
              fragment(
                "DATE_TRUNC('quarter', COALESCE(?,?))::date",
                act.working_day_start,
                act.working_day_end
              )
          },
          group_by: [
            fragment(
              "DATE_TRUNC('quarter', COALESCE(?,?))::date",
              act.working_day_start,
              act.working_day_end
            )
          ]
        )

      :year ->
        from(act in qry,
          select_merge: %{
            year:
              fragment(
                "DATE_TRUNC('year', COALESCE(?,?))::date",
                act.working_day_start,
                act.working_day_end
              )
          },
          group_by: [
            fragment(
              "DATE_TRUNC('year', COALESCE(?,?))::date",
              act.working_day_start,
              act.working_day_end
            )
          ]
        )

      :employer ->
        from(act in qry,
          select_merge: %{employer: act.employer},
          group_by: [act.employer]
        )

      :employer_service ->
        from(act in qry,
          select_merge: %{employer_service: act.employer_service},
          group_by: [act.employer_service]
        )

      :service_class ->
        from(act in qry,
          select_merge: %{service_class: act.service_class},
          group_by: [act.service_class]
        )

      :earning_type ->
        from(act in qry,
          select_merge: %{earning_type: act.earning_type},
          group_by: [act.earning_type]
        )

      _ ->
        qry
    end
  end

  def get_timespans_for_user_workday(user_id, work_day, calc_method) do
    qry =
      get_timespans_query(user_id)
      |> filter_timespans_query_calc_method(calc_method)
      |> filter_timespans_query_date_range(work_day, work_day)

    from(ts in qry,
      preload: [:allocations]
    )
    |> Repo.all()
  end

  @doc """
  For a user, identify the earliest and most recent work date for which we have spans.
  This is used when recalculating a user's work time.
  """
  def get_timespan_date_range(user_id) do
    from(ts in get_timespans_query(user_id),
      select: [min(ts.work_date), max(ts.work_date)]
    )
    |> Repo.one()
  end

  @doc """
  For a user, identify the years in which they have timespans recorded
  """
  def get_timespan_years(user_id) do
    get_timespans_query(user_id)
    |> select([ts], fragment("DISTINCT DATE_PART('year', ?)::int", ts.work_date))
    |> Repo.all()
  end

  defp get_timespans_query(user_id_or_ids) do
    user_id_or_ids = List.wrap(user_id_or_ids)

    from(ts in Timespan,
      as: :ts,
      where: ts.user_id in ^user_id_or_ids
    )
  end

  defp filter_timespans_query_date_range(qry, work_date_start, work_date_end) do
    qry =
      if is_nil(work_date_start) do
        qry
      else
        from(ts in qry,
          where: ts.work_date >= ^work_date_start
        )
      end

    if is_nil(work_date_end) do
      qry
    else
      from(ts in qry,
        where: ts.work_date <= ^work_date_end
      )
    end
  end

  defp filter_timespans_query_calc_method(qry, calc_method) do
    if is_nil(calc_method) do
      qry
    else
      from(ts in qry,
        where: ts.calc_method == ^calc_method
      )
    end
  end

  def update_timespans_and_allocations_for_user_workday(user, work_day) do
    update_timespans_and_allocations_for_user_workday(user, work_day, "user_facing")
    # update_timespans_and_allocations_for_user_workday(user, work_day, "auto_calculated")
  end

  def update_timespans_and_allocations_for_user_workday(user, work_day, calc_method) do
    # get the existing timespans and allocations.  These will be used later to delete
    # anything that no longer belongs
    db_timespans = get_timespans_for_user_workday(user.id, work_day, calc_method)
    db_timespan_ids = Enum.map(db_timespans, fn ts -> ts.id end)

    db_allocations = Enum.flat_map(db_timespans, fn ts -> ts.allocations end)
    db_allocation_ids = Enum.map(db_allocations, fn a -> a.id end)

    # calculate timespans based on current data
    timespans = calculate_timespans_and_allocations_for_user_workday(user, work_day, calc_method)

    multi = Ecto.Multi.new()

    [multi, _, ref_timespan_ids, ref_alloc_ids] =
      Enum.reduce(timespans, [multi, 0, [], []], fn timespan,
                                                    [multi, idx, ref_timespan_ids, ref_alloc_ids] ->
        db_timespan = find_timespan_in_list(db_timespans, work_day, timespan.start_time)

        # if this is a new timespan
        if is_nil(db_timespan) do
          changeset =
            %Timespan{
              user_id: user.id,
              work_date: work_day,
              calc_method: calc_method
            }
            |> Timespan.changeset(timespan, timespan.allocations)

          multi = Ecto.Multi.insert(multi, idx, changeset)

          [multi, idx + 1, ref_timespan_ids, ref_alloc_ids]
        else
          ref_timespan_ids = List.insert_at(ref_timespan_ids, -1, db_timespan.id)

          changeset = Timespan.changeset(db_timespan, timespan)

          multi = Ecto.Multi.update(multi, idx, changeset)

          # match against existing allocations updating where necessary
          [multi, idx, ref_alloc_ids] =
            Enum.reduce(timespan.allocations, [multi, idx + 1, ref_alloc_ids], fn alloc,
                                                                                  [
                                                                                    multi,
                                                                                    idx,
                                                                                    ref_alloc_ids
                                                                                  ] ->
              db_alloc =
                find_allocation_in_list(
                  db_timespan.allocations,
                  alloc.start_time,
                  Map.get(alloc, :activity_id)
                )

              alloc_changeset =
                TimespanAllocation.changeset(
                  db_alloc ||
                    %TimespanAllocation{
                      timespan: db_timespan
                    },
                  alloc
                )

              if is_nil(db_alloc) do
                multi = Ecto.Multi.insert(multi, idx, alloc_changeset)
                [multi, idx + 1, ref_alloc_ids]
              else
                ref_alloc_ids = List.insert_at(ref_alloc_ids, -1, db_alloc.id)
                multi = Ecto.Multi.update(multi, idx, alloc_changeset)
                [multi, idx + 1, ref_alloc_ids]
              end
            end)

          [multi, idx, ref_timespan_ids, ref_alloc_ids]
        end
      end)

    # If there are allocations that no longer belong, delete them
    multi =
      if Enum.any?(db_allocation_ids) do
        Ecto.Multi.delete_all(
          multi,
          :delete_allocs,
          from(a in TimespanAllocation,
            where: a.id in ^db_allocation_ids,
            where: a.id not in ^ref_alloc_ids
          )
        )
      else
        multi
      end

    # If there are timespans that no longer belong, delete them.
    multi =
      if Enum.any?(db_timespan_ids) do
        Ecto.Multi.delete_all(
          multi,
          :delete_timespans,
          from(a in Timespan,
            where: a.id in ^db_timespan_ids,
            where: a.id not in ^ref_timespan_ids
          )
        )
      else
        multi
      end

    with {:ok, result} <- Repo.transaction(multi) do
      CalculatePerformanceForUserWindow.schedule_jobs(user.id, work_day)
      {:ok, result}
    end
  end

  def calculate_timespans_and_allocations_for_user_workday(
        user,
        work_day,
        "user_facing" = _calc_metrhod
      ) do
    now = DateTime.utc_now()

    # Use the activity data to pick the timezone for the day that they worked
    # If not available, look forward and backward.  If not available pick the user info
    timezone = Activities.identify_timezone_for_user_work_date(user, work_day)

    [work_day_start, work_day_end] = DateTimeUtil.working_day_bounds(work_day, timezone)

    # If the start date is in the future, exit
    if DateTime.compare(work_day_start, now) == :gt do
      []
    else
      # don't calculate past now
      work_day_end = Enum.min([work_day_end, now], DateTime)

      # get shifts
      shifts = get_normalized_shifts_for_workday(user, work_day_start, work_day_end)

      # get activities for the day
      job_activities = get_normalized_job_activities_for_workday(user, work_day)

      # divide the day into timespans based on shifts
      timespans = identify_timespans_using_shifts(shifts, work_day_start, work_day_end)

      # for timespans not associated to shifts, calculate based on auto-calc approach
      timespans =
        Enum.flat_map(timespans, fn ts ->
          if Enum.any?(Map.get(ts, :shift_ids) || []) do
            [ts]
          else
            activities =
              filter_activities_for_time_window(job_activities, ts.start_time, ts.end_time)

            identify_timespans_using_jobs(
              activities,
              ts.start_time,
              ts.end_time,
              @calc_shift_settings_user_facing
            )
          end
        end)
        |> Enum.filter(fn ts -> DateTime.compare(ts.end_time, ts.start_time) == :gt end)

      # merge contiguous timespans
      [timespans, _] =
        Enum.reduce(timespans, [[], nil], fn ts, [timespans, last_ts] ->
          cond do
            is_nil(last_ts) ->
              [[ts], ts]

            DateTime.compare(last_ts.end_time, ts.start_time) == :eq ->
              adjusted_ts =
                last_ts
                |> Map.put(:end_time, ts.end_time)
                |> Map.put(
                  :shift_ids,
                  Map.get(last_ts, :shift_ids, []) ++ Map.get(ts, :shift_ids, [])
                )

              [List.replace_at(timespans, -1, adjusted_ts), adjusted_ts]

            true ->
              [List.insert_at(timespans, -1, ts), ts]
          end
        end)

      # ensure that no timespans are future dated (open shift or open job)
      timespans =
        timespans
        |> Enum.filter(fn ts -> DateTime.compare(ts.start_time, now) in [:lt, :eq] end)
        |> Enum.map(fn ts ->
          Map.put(
            ts,
            :end_time,
            DateTimeUtil.ceiling_minute(Enum.min([now, ts.end_time], DateTime))
          )
        end)

      # divide each timespan into allocations of engaged and non-engaged time using jobs
      timespans =
        Enum.map(timespans, fn timespan ->
          Map.put(
            timespan,
            :allocations,
            identify_allocations_for_time_range(
              job_activities,
              timespan.start_time,
              timespan.end_time
            )
          )
        end)

      timespans
      |> set_timespan_durations()
      |> set_device_mileage_and_coverage(user)
      |> set_platform_mileage_and_coverage()
      |> set_selected_mileage_and_coverage()
    end
  end

  def calculate_timespans_and_allocations_for_user_workday(
        user,
        work_day,
        "auto_calculated"
      ) do
    now = DateTime.utc_now()

    # Use the activity data to pick the timezone for the day that they worked
    # If not available, look forward and backward.  If not available pick the user info
    timezone = Activities.identify_timezone_for_user_work_date(user, work_day)

    [work_day_start, work_day_end] = DateTimeUtil.working_day_bounds(work_day, timezone)

    # If the start date is in the future, exit
    if DateTime.compare(work_day_start, now) == :gt do
      []
    else
      # don't calculate past now
      work_day_end = Enum.min([work_day_end, now], DateTime)

      # get activities for the day
      job_activities = get_normalized_job_activities_for_workday(user, work_day)

      # divide the day into timespans based on jobs
      timespans =
        identify_timespans_using_jobs(
          job_activities,
          work_day_start,
          work_day_end,
          @calc_shift_settings_auto_calculated
        )

      # ensure that no timespans are future dated (open shift or open job)
      timespans =
        timespans
        |> Enum.filter(fn ts -> DateTime.compare(ts.start_time, now) in [:lt, :eq] end)
        |> Enum.map(fn ts ->
          Map.put(
            ts,
            :end_time,
            DateTimeUtil.ceiling_minute(Enum.min([now, ts.end_time], DateTime))
          )
        end)

      # divide each timespan into allocations of engaged and non-engaged time using jobs
      timespans =
        Enum.map(timespans, fn timespan ->
          Map.put(
            timespan,
            :allocations,
            identify_allocations_for_time_range(
              job_activities,
              timespan.start_time,
              timespan.end_time
            )
          )
        end)

      timespans
      |> set_timespan_durations()
      |> set_device_mileage_and_coverage(user)
      |> set_platform_mileage_and_coverage()
      |> set_selected_mileage_and_coverage()
    end
  end

  # Use shifts to break out a range of time into spans of contiguous time
  # based on using shift-tracker.  Cleans up any overlapping shifts.  When complete, the entire range will
  # be covered by timespans
  defp identify_timespans_using_shifts(shifts, range_start_time, range_end_time) do
    [timespans, last_timespan] =
      shifts
      |> Enum.reduce([[], nil], fn shift, [timespans, last_timespan] ->
        cond do
          # This shift is the first timespan of day and there is a need
          # to add a filler timespan before shift starts
          is_nil(last_timespan) and DateTime.compare(shift.start_time, range_start_time) == :gt ->
            timespans =
              List.insert_at(timespans, -1, %{
                start_time: range_start_time,
                end_time: shift.start_time,
                shift_ids: []
              })

            timespan = %{
              start_time: shift.start_time,
              end_time: shift.end_time,
              shift_ids: [shift.id]
            }

            [List.insert_at(timespans, -1, timespan), timespan]

          # This shift is the first timespan of day
          # and it starts at the start of day (no need for filler timespan)
          is_nil(last_timespan) ->
            timespan = %{
              start_time: shift.start_time,
              end_time: shift.end_time,
              shift_ids: [shift.id]
            }

            [List.insert_at(timespans, -1, timespan), timespan]

          # next shift starts after the end of the current timespan
          # There's a gap between shifts, so add a filler  timespan as well
          DateTime.compare(shift.start_time, last_timespan.end_time) == :gt ->
            timespans =
              List.insert_at(timespans, -1, %{
                start_time: last_timespan.end_time,
                end_time: shift.start_time,
                shift_ids: []
              })

            timespan = %{
              start_time: shift.start_time,
              end_time: shift.end_time,
              shift_ids: [shift.id]
            }

            [List.insert_at(timespans, -1, timespan), timespan]

          # otherwise, extend the last timespan to cover this shift as well.
          # indicates overlapping or tail-to-head shifts
          true ->
            timespan =
              last_timespan
              |> Map.put(:end_time, Enum.max([shift.end_time, last_timespan.end_time], DateTime))
              |> Map.put(:shift_ids, List.insert_at(last_timespan.shift_ids, -1, shift.id))

            [List.replace_at(timespans, -1, timespan), timespan]
        end
      end)

    cond do
      # if no timespans were created for the day, create a single timespan
      # to represent the entire day
      is_nil(last_timespan) ->
        [
          %{
            start_time: range_start_time,
            end_time: range_end_time,
            shift_ids: []
          }
        ]

      # if the last timespan finishes before the end of the day,
      # add filler timespan for the end of day
      DateTime.compare(last_timespan.end_time, range_end_time) == :lt ->
        List.insert_at(timespans, -1, %{
          start_time: last_timespan.end_time,
          end_time: range_end_time,
          shift_ids: []
        })

      true ->
        timespans
    end
  end

  # Use activities to break out a range of time into spans of contiguous working time.  Add padding before and
  # after and break work time based on a gap amount
  defp identify_timespans_using_jobs(jobs, range_start_time, range_end_time, settings) do
    padding_before_minutes = Map.get(settings, :padding_before_minutes, 0)
    padding_after_minutes = Map.get(settings, :padding_after_minutes, 0)
    padding_gap_break_miutes = Map.get(settings, :padding_gap_break_miutes, 0)

    [timespans, last_timespan] =
      Enum.reduce(jobs, [[], nil], fn job, [timespans, last_timespan] ->
        job_start_time = Enum.max([job.start_time, range_start_time], DateTime)
        job_end_time = Enum.min([job.end_time || range_end_time, range_end_time], DateTime)

        cond do
          # This job is the first job of the day
          is_nil(last_timespan) ->
            new_timespan_start = DateTime.add(job_start_time, -padding_before_minutes, :minute)

            new_timespan_start = Enum.max([range_start_time, new_timespan_start], DateTime)

            new_timespan = %{
              start_time: new_timespan_start,
              end_time: job_end_time
            }

            [List.insert_at(timespans, -1, new_timespan), new_timespan]

          # next job starts more than x(30) minutes after the end of the last job
          # this indicates a gap in calculated shifts
          DateTime.compare(
            job_start_time,
            DateTime.add(last_timespan.end_time, padding_gap_break_miutes, :minute)
          ) == :gt ->
            # close out last timespan by adding padding to end
            last_timespan_end =
              DateTime.add(last_timespan.end_time, padding_after_minutes, :minute)

            last_timespan_end = Enum.min([range_end_time, last_timespan_end], DateTime)
            last_timespan = Map.put(last_timespan, :end_time, last_timespan_end)

            timespans = List.replace_at(timespans, -1, last_timespan)

            new_timespan_start = DateTime.add(job_start_time, -padding_before_minutes, :minute)

            new_timespan_start = Enum.max([range_start_time, new_timespan_start], DateTime)

            new_timespan = %{
              start_time: new_timespan_start,
              end_time: job_end_time
            }

            [List.insert_at(timespans, -1, new_timespan), new_timespan]

          # otherwise, extend the last timespan to cover this job as well.
          # indicates overlapping or tail-to-head jobs
          true ->
            last_timespan_end = Enum.max([job_end_time, last_timespan.end_time], DateTime)
            last_timespan_end = Enum.min([last_timespan_end, range_end_time], DateTime)

            last_timespan = Map.put(last_timespan, :end_time, last_timespan_end)

            [List.replace_at(timespans, -1, last_timespan), last_timespan]
        end
      end)

    timespans =
      cond do
        is_nil(last_timespan) ->
          timespans

        DateTime.compare(last_timespan.end_time, range_end_time) == :lt ->
          last_timespan_end = DateTime.add(last_timespan.end_time, padding_after_minutes, :minute)

          last_timespan_end = Enum.min([range_end_time, last_timespan_end], DateTime)
          last_timespan = Map.put(last_timespan, :end_time, last_timespan_end)

          List.replace_at(timespans, -1, last_timespan)

        true ->
          timespans
      end

    # Remove any timespans that don't have any time associated with them
    # TODO: figure out how these are being calculated
    timespans
    |> Enum.filter(fn ts -> DateTime.compare(ts.start_time, ts.end_time) == :lt end)
  end

  # Associate activities/jobs and non-engaged time with a timespan
  # When complete, the entire timespan will be covered either allocations
  # Although non-engaged allocations do not overlap, activity/job based allocations can
  defp identify_allocations_for_time_range(activities, range_start_time, range_end_time) do
    [allocations, last_end_time] =
      activities
      |> filter_activities_for_time_window(range_start_time, range_end_time)
      |> Enum.reduce([[], nil], fn activity, [allocations, last_end_time] ->
        activity_start_time = Enum.max([range_start_time, activity.start_time], DateTime)
        activity_end_time = Enum.min([range_end_time, activity.end_time], DateTime)

        cond do
          # first job it starts after the timespan starts
          # create starting non-engaged allocation and an allocation for the job
          is_nil(last_end_time) and
              DateTime.compare(activity_start_time, range_start_time) == :gt ->
            allocations =
              List.insert_at(
                allocations,
                -1,
                %{
                  start_time: range_start_time,
                  end_time: activity_start_time
                }
                |> set_allocation_properties()
              )

            allocation =
              %{
                start_time: activity_start_time,
                end_time: activity_end_time
              }
              |> set_allocation_properties(activity)

            [List.insert_at(allocations, -1, allocation), allocation.end_time]

          # this is the first job and it starts before or at the timespan start
          # just create allocation for the job
          is_nil(last_end_time) ->
            allocation =
              %{
                start_time: activity_start_time,
                end_time: activity_end_time
              }
              |> set_allocation_properties(activity)

            [List.insert_at(allocations, -1, allocation), allocation.end_time]

          # this job starts after the last allocation ended
          # create non-engaged timespan for the time between and then an allocation for the job
          DateTime.compare(activity_start_time, last_end_time) == :gt ->
            allocations =
              List.insert_at(
                allocations,
                -1,
                %{
                  start_time: last_end_time,
                  end_time: activity_start_time
                }
                |> set_allocation_properties()
              )

            allocation =
              %{
                start_time: activity_start_time,
                end_time: activity_end_time
              }
              |> set_allocation_properties(activity)

            [List.insert_at(allocations, -1, allocation), allocation.end_time]

          # otherwise, create an engaged timespan for the job and extended out the last_end_time as needed
          true ->
            allocation =
              %{
                start_time: activity_start_time,
                end_time: activity_end_time
              }
              |> set_allocation_properties(activity)

            new_end_time = Enum.max([allocation.end_time, last_end_time], DateTime)

            [List.insert_at(allocations, -1, allocation), new_end_time]
        end
      end)

    allocations =
      cond do
        # if there are no activities for the timespan
        # create a non-engaged allocation for the entire timespan
        is_nil(last_end_time) ->
          List.insert_at(
            allocations,
            -1,
            %{
              start_time: range_start_time,
              end_time: range_end_time
            }
            |> set_allocation_properties()
          )

        # if there is an unaccounted time window at the end of the timepsan,
        # create a non-engaged allocation for it.
        DateTime.compare(last_end_time, range_end_time) == :lt ->
          List.insert_at(
            allocations,
            -1,
            %{
              start_time: last_end_time,
              end_time: range_end_time
            }
            |> set_allocation_properties()
          )

        true ->
          allocations
      end

    Enum.filter(allocations, fn alloc ->
      DateTime.compare(alloc.start_time, alloc.end_time) == :lt
    end)
  end

  defp set_allocation_properties(alloc) do
    Map.put(alloc, :duration_seconds, DateTime.diff(alloc.end_time, alloc.start_time))
  end

  defp set_allocation_properties(alloc, activity) do
    duration = DateTime.diff(alloc.end_time, alloc.start_time)

    activity_coverage =
      if activity.duration_seconds == 0 do
        0
      else
        duration / activity.duration_seconds
      end

    miles_per_second = Enum.max([Map.get(activity, :miles_per_second), 0.0])

    miles =
      cond do
        is_nil(miles_per_second) ->
          nil

        miles_per_second < 0 ->
          nil

        true ->
          duration * miles_per_second
      end

    alloc
    |> Map.merge(%{
      activity_id: activity.id,
      activity_extends_before: DateTime.compare(activity.start_time, alloc.start_time) == :lt,
      activity_extends_after: DateTime.compare(activity.end_time, alloc.end_time) == :gt,
      activity_coverage_percent: activity_coverage,
      duration_seconds: duration,
      platform_miles_per_second: miles_per_second,
      platform_miles: miles
    })
  end

  # Set the duration and engaged duration removing overlaps
  defp set_timespan_durations(timespans) do
    Enum.map(timespans, fn timespan ->
      # total duration of the timespan
      timespan_duration = DateTime.diff(timespan.end_time, timespan.start_time)

      # total non-engaged time for the timespan (b/c it doesnot overlap)
      timespan_duration_non_engaged =
        timespan.allocations
        |> Enum.filter(fn alloc -> is_nil(Map.get(alloc, :activity_id)) end)
        |> Enum.map(fn alloc -> alloc.duration_seconds end)
        |> Enum.sum()

      timespan
      |> Map.put(:duration_seconds, timespan_duration)
      |> Map.put(:duration_seconds_engaged, timespan_duration - timespan_duration_non_engaged)
    end)
  end

  # Set the distance captured from the GPS removing overlaps
  defp set_device_mileage_and_coverage(timespans, user) do
    Enum.map(timespans, fn timespan ->
      # capture mileage stats for the allocations
      timespan =
        Map.put(
          timespan,
          :allocations,
          Enum.map(timespan.allocations, fn alloc ->
            Map.merge(
              alloc,
              estimate_device_mileage_for_time_range(user.id, alloc.start_time, alloc.end_time)
            )
          end)
        )

      # capture mileage stats for the entire timespan
      timespan =
        Map.merge(
          timespan,
          estimate_device_mileage_for_time_range(
            user.id,
            timespan.start_time,
            timespan.end_time
          )
        )

      # total non-engaged time and distance for the timespan (b/c it doesnot overlap)
      [distance_non_engaged, deduction_non_engaged] =
        timespan.allocations
        |> Enum.filter(fn alloc -> is_nil(Map.get(alloc, :activity_id)) end)
        |> Enum.reduce([0, 0], fn alloc, [distance, deduction] ->
          if is_nil(alloc.device_miles) do
            [distance, deduction]
          else
            [
              (distance || 0) + alloc.device_miles,
              (deduction || 0) + alloc.device_miles_deduction_cents
            ]
          end
        end)

      # set engaged time and distance as a subtraction from total (total - non-engaged = engaged)
      # this avoids overlapping time and mileage
      if is_nil(distance_non_engaged) do
        timespan
        |> Map.put(:device_miles_engaged, timespan.device_miles)
        |> Map.put(:device_miles_deduction_cents_engaged, timespan.device_miles_deduction_cents)
      else
        timespan
        |> Map.put(
          :device_miles_engaged,
          Enum.max([0, (timespan.device_miles || 0) - distance_non_engaged])
        )
        |> Map.put(
          :device_miles_deduction_cents_engaged,
          Enum.max([0, (timespan.device_miles_deduction_cents || 0) - deduction_non_engaged])
        )
      end
    end)
  end

  defp set_platform_mileage_and_coverage(timespans) do
    Enum.map(timespans, fn ts ->
      if ts.duration_seconds_engaged > 0 do
        Map.merge(ts, estimate_platform_mileage_for_timespan(ts))
      else
        ts
      end
    end)
  end

  # Use platform reported distance information to estimate the mileage
  # for the timespan.
  defp estimate_platform_mileage_for_timespan(timespan) do
    # get activities that have mileage a information
    allocations =
      timespan.allocations
      |> Enum.filter(fn a -> not is_nil(Map.get(a, :platform_miles_per_second)) end)

    # build a list of time points for which to take measurements
    timepoints =
      (Enum.map(allocations, fn a -> a.start_time end) ++
         Enum.map(allocations, fn a -> a.end_time end))
      |> Enum.uniq()
      |> Enum.sort(DateTime)

    # for each timepoint, average available speeds and estimate
    # the distance
    [_, covered_time, total_mileage, _] =
      Enum.reduce(timepoints, [nil, 0, 0, []], fn timepoint,
                                                  [
                                                    prev_timepoint,
                                                    covered_time,
                                                    total_mileage,
                                                    mileage_rates
                                                  ] ->
        next_mileage_rates =
          allocations
          |> Enum.filter(fn a ->
            DateTime.compare(timepoint, a.start_time) in [:gt, :eq] and
              DateTime.compare(timepoint, a.end_time) == :lt
          end)
          |> Enum.map(fn a -> a.platform_miles_per_second end)

        cond do
          is_nil(prev_timepoint) ->
            [timepoint, covered_time, total_mileage, next_mileage_rates]

          not Enum.any?(mileage_rates) ->
            [timepoint, covered_time, total_mileage, next_mileage_rates]

          true ->
            count_seconds = DateTime.diff(timepoint, prev_timepoint)
            sum_rates = Enum.sum(mileage_rates)
            count_rates = Enum.count(mileage_rates)
            avg_speed = sum_rates / count_rates

            [
              timepoint,
              covered_time + count_seconds,
              total_mileage + avg_speed * count_seconds,
              next_mileage_rates
            ]
        end
      end)

    coverage_percent = Enum.min([covered_time / timespan.duration_seconds, 1])
    coverage_percent_engaged = Enum.min([covered_time / timespan.duration_seconds_engaged, 1])

    result = %{
      platform_miles_quality_percent: Float.round(coverage_percent, 3)
    }

    if covered_time == 0 do
      result
    else
      platform_miles = total_mileage / coverage_percent

      platform_miles_engaged = total_mileage / coverage_percent_engaged

      Map.merge(result, %{
        platform_miles: platform_miles,
        platform_miles_deduction_cents:
          Irs.calculate_irs_expense(timespan.start_time, platform_miles),
        platform_miles_engaged: platform_miles_engaged,
        platform_miles_deduction_cents_engaged:
          Irs.calculate_irs_expense(timespan.start_time, platform_miles_engaged)
      })
    end
  end

  # Capture the mileage from the device, measurement of
  # coverage and quality, and the irs deduction and information
  def estimate_device_mileage_for_time_range(user_id, start_time, end_time) do
    points_qry =
      from(p in Point,
        select: %{
          recorded_at: p.recorded_at,
          recorded_at_bin: fragment("DATE_BIN('10 seconds', ?, '1/1/1970')", p.recorded_at),
          geometry: p.geometry
        },
        where: p.user_id == ^user_id,
        where: fragment("? IS NULL OR ? <= 1000.0", p.accuracy, p.accuracy),
        where: fragment("? BETWEEN ? AND ?", p.recorded_at, ^start_time, ^end_time),
        order_by: [asc: p.recorded_at]
      )

    mileage_stats =
      from(p in subquery(points_qry),
        select: %{
          device_miles:
            fragment(
              "ST_Length(ST_MakeLine(?)::geography) * 0.0006214",
              p.geometry
            ),
          gps_samples_actual:
            fragment(
              "COUNT(DISTINCT ?)",
              p.recorded_at_bin
            ),
          recorded_at_min: min(p.recorded_at),
          recorded_at_max: max(p.recorded_at)
        }
      )
      |> Repo.one(timeout: 30_000)

    # If there are no meaningul GPS samples
    if is_nil(mileage_stats.device_miles) or
         DateTime.compare(mileage_stats.recorded_at_min, mileage_stats.recorded_at_max) == :eq do
      %{
        device_miles_quality_percent: nil,
        device_miles: nil,
        device_miles_deduction_cents: nil
      }
    else
      duration_gps = DateTime.diff(mileage_stats.recorded_at_max, mileage_stats.recorded_at_min)
      duration_total = DateTime.diff(end_time, start_time)

      gps_samples_possible =
        duration_gps
        |> Decimal.div(10)
        |> Decimal.round(0, :up)
        |> Decimal.to_integer()

      gps_coverage_percent = duration_gps / duration_total

      device_miles_quality_percent =
        if gps_samples_possible > 0 do
          Enum.min([mileage_stats.gps_samples_actual / gps_samples_possible, 1])
        else
          0
        end

      # quality is the % of total time captured by GPS * the % of bins with GPS data
      device_miles_quality_percent = device_miles_quality_percent * gps_coverage_percent

      device_miles =
        if gps_coverage_percent == 0 do
          nil
        else
          mileage_stats.device_miles * (1 / gps_coverage_percent)
        end

      %{
        # These don't get saved to the database, but helpful if debugging
        duration_gps: duration_gps,
        device_samples_possible: gps_samples_possible,
        device_samples_actual: mileage_stats.gps_samples_actual,
        device_samples_coverage_percent: device_miles_quality_percent,
        device_time_coverage_percent: duration_gps / duration_total,

        # These are saved to the database
        device_miles_quality_percent: device_miles_quality_percent,
        device_miles: device_miles,
        device_miles_deduction_cents: Irs.calculate_irs_expense(start_time, device_miles)
      }
    end
  end

  # Compare Device Mileage and Platform mileage and select the better choice
  defp set_selected_mileage_and_coverage(timespans) do
    Enum.map(timespans, fn ts -> Map.merge(ts, get_selected_mileage_and_coverage(ts)) end)
  end

  defp get_selected_mileage_and_coverage(timespan) do
    platform_quality = Map.get(timespan, :platform_miles_quality_percent) || 0
    device_quality = Map.get(timespan, :device_miles_quality_percent) || 0

    cond do
      # if there is no platform miles or the device miles quality > 75%, choose device
      device_quality >= 0.75 or platform_quality == 0 ->
        %{
          selected_miles: Map.get(timespan, :device_miles),
          selected_miles_quality_percent: Map.get(timespan, :device_miles_quality_percent),
          selected_miles_engaged: Map.get(timespan, :device_miles_engaged),
          selected_miles_deduction_cents: Map.get(timespan, :device_miles_deduction_cents),
          selected_miles_deduction_cents_engaged:
            Map.get(timespan, :device_miles_deduction_cents_engaged)
        }

      # if there are no device miles, choose platform
      device_quality == 0 ->
        %{
          selected_miles: Map.get(timespan, :platform_miles),
          selected_miles_quality_percent: Map.get(timespan, :platform_miles_quality_percent),
          selected_miles_engaged: Map.get(timespan, :platform_miles_engaged),
          selected_miles_deduction_cents: Map.get(timespan, :platform_miles_deduction_cents),
          selected_miles_deduction_cents_engaged:
            Map.get(timespan, :platform_miles_deduction_cents_engaged)
        }

      # if the quality is within 25% of each other, average the values
      abs(platform_quality - device_quality) <= 0.25 ->
        %{
          selected_miles: (timespan.platform_miles + timespan.device_miles) / 2,
          selected_miles_quality_percent: (platform_quality + device_quality) / 2,
          selected_miles_engaged:
            (timespan.platform_miles_engaged + timespan.device_miles_engaged) / 2,
          selected_miles_deduction_cents:
            ((timespan.platform_miles_deduction_cents + timespan.device_miles_deduction_cents) / 2)
            |> Decimal.from_float()
            |> Decimal.round()
            |> Decimal.to_integer(),
          selected_miles_deduction_cents_engaged:
            ((timespan.platform_miles_deduction_cents_engaged +
                timespan.device_miles_deduction_cents_engaged) / 2)
            |> Decimal.from_float()
            |> Decimal.round()
            |> Decimal.to_integer()
        }

      # select better - device
      device_quality >= platform_quality ->
        %{
          selected_miles: Map.get(timespan, :device_miles),
          selected_miles_quality_percent: Map.get(timespan, :device_miles_quality_percent),
          selected_miles_engaged: Map.get(timespan, :device_miles_engaged),
          selected_miles_deduction_cents: Map.get(timespan, :device_miles_deduction_cents),
          selected_miles_deduction_cents_engaged:
            Map.get(timespan, :device_miles_deduction_cents_engaged)
        }

      # select better - platform
      true ->
        %{
          selected_miles: Map.get(timespan, :platform_miles),
          selected_miles_quality_percent: Map.get(timespan, :platform_miles_quality_percent),
          selected_miles_engaged: Map.get(timespan, :platform_miles_engaged),
          selected_miles_deduction_cents: Map.get(timespan, :platform_miles_deduction_cents),
          selected_miles_deduction_cents_engaged:
            Map.get(timespan, :platform_miles_deduction_cents_engaged)
        }
    end
  end

  # Filter the list of activities to only include the activities for the
  # time window in question
  defp filter_activities_for_time_window(activities, start_time, end_time) do
    activities
    |> Enum.filter(fn activity ->
      DateTimeUtil.is_between(
        activity.start_time,
        start_time,
        end_time
      ) or
        DateTimeUtil.is_between(
          activity.end_time,
          start_time,
          end_time
        ) or
        (DateTime.compare(activity.start_time, start_time) == :lt and
           DateTime.compare(activity.end_time, end_time) == :gt)
    end)
    |> Enum.sort_by(fn activity -> activity.start_time end, DateTime)
  end

  # Grab activities for the workday and normalize the start/end work time (P3) to the minute
  defp get_normalized_job_activities_for_workday(user, work_date) do
    Activities.get_activities(user.id, %{
      work_date_start: work_date,
      work_date_end: work_date,
      earning_types: Activities.work_earning_types(),
      status: Activities.work_activity_statuses()
    })
    |> Enum.filter(fn activity ->
      not is_nil(activity.timestamp_work_start) and
        not is_nil(activity.timestamp_work_end) and
        DateTime.compare(activity.timestamp_work_start, activity.timestamp_work_end) == :lt
    end)
    |> Enum.map(fn activity ->
      activity = Map.merge(activity, get_normalized_start_end_and_duration_for_activity(activity))
      Map.merge(activity, get_normalized_mile_rate_for_activity(activity))
    end)
    |> Enum.sort_by(fn s -> s.start_time end, DateTime)
  end

  defp get_normalized_start_end_and_duration_for_activity(activity) do
    start_time =
      DateTimeUtil.floor_minute(
        activity.timestamp_work_start || DateTime.add(activity.timestamp_work_end, -60, :second)
      )

    end_time =
      DateTimeUtil.ceiling_minute(
        activity.timestamp_work_end || DateTime.add(activity.timestamp_work_start, 60, :second)
      )

    end_time =
      if DateTime.compare(start_time, end_time) == :eq do
        DateTime.add(end_time, 60, :second)
      else
        end_time
      end

    %{
      start_time: start_time,
      end_time: end_time,
      duration_seconds: DateTime.diff(end_time, start_time)
    }
  end

  defp get_normalized_mile_rate_for_activity(activity) do
    if is_nil(activity.distance) or activity.duration_seconds == 0 do
      %{}
    else
      %{
        miles_per_second:
          Decimal.to_float(Decimal.div(activity.distance, activity.duration_seconds))
      }
    end
  end

  # Grab shifts and normalize start/end times to the minute
  defp get_normalized_shifts_for_workday(user, work_day_start, work_day_end) do
    Shifts.query_shifts_for_user(user.id)
    |> Shifts.query_shifts_filter_time_range(work_day_start, work_day_end)
    |> Repo.all()
    |> Enum.map(fn s ->
      %{
        id: s.id,
        start_time: DateTimeUtil.floor_minute(Enum.max([s.start_time, work_day_start], DateTime)),
        end_time:
          DateTimeUtil.ceiling_minute(
            Enum.min([s.end_time || work_day_end, work_day_end], DateTime)
          )
      }
    end)
    |> Enum.sort_by(fn s -> s.start_time end, DateTime)
  end

  defp find_timespan_in_list(existing_timespans, work_date, start_time) do
    existing_timespans
    |> Enum.find(fn ts ->
      Date.compare(ts.work_date, work_date) == :eq and
        DateTime.compare(ts.start_time, start_time) == :eq
    end)
  end

  defp find_allocation_in_list(existing_allocations, start_time, activity_id) do
    existing_allocations
    |> Enum.find(fn alloc ->
      DateTime.compare(alloc.start_time, start_time) == :eq and alloc.activity_id == activity_id
    end)
  end
end
