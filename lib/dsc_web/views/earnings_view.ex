defmodule DriversSeatCoopWeb.EarningsView do
  use DriversSeatCoopWeb, :view
  alias DriversSeatCoop.Util.MathUtil

  def render("detail.json", %{
        timespans: timespans
      }) do
    %{data: Enum.map(timespans, fn ts -> render_timespan(ts) end)}
  end

  def render("index.json", %{
        time_grouping: nil,
        time_and_mileage: time_and_mileage,
        job_earnings: job_earnings,
        other_earnings: other_earnings
      }) do
    other_earnings = Enum.at(other_earnings || [], 0)
    job_earnings = Enum.at(job_earnings || [], 0)
    time_and_mileage = Enum.at(time_and_mileage || [], 0)

    result =
      %{}
      |> Map.merge(other_earnings || %{})
      |> Map.merge(job_earnings || %{})
      |> Map.merge(time_and_mileage || %{})

    %{
      data: result
    }
  end

  def render("index.json", %{
        time_grouping: time_grouping,
        time_and_mileage: time_and_mileage,
        job_earnings: job_earnings,
        other_earnings: other_earnings
      }) do
    time_grouping = String.to_atom(time_grouping)

    result =
      (List.wrap(job_earnings) ++ List.wrap(other_earnings))
      |> Enum.reduce(%{}, fn e, model ->
        key = Map.get(e, time_grouping)

        val =
          Map.get(model, key, %{})
          |> Map.merge(e)

        Map.put(model, key, val)
      end)

    result =
      Enum.reduce(time_and_mileage, result, fn tm, model ->
        key = Map.get(tm, time_grouping)

        val =
          Map.get(model, key, %{})
          |> Map.merge(tm)

        Map.put(model, key, val)
      end)
      |> Map.values()

    %{
      data: result
    }
  end

  def render("activity.json", %{
        activity: activity
      }) do
    %{
      data: render_activity(activity)
    }
  end

  def render("activities.json", %{
        activities: activities
      }) do
    %{
      data: Enum.map(activities, fn a -> render_activity(a) end)
    }
  end

  @time_and_mileage_template %{
    count_work_days: 0,
    device_miles: Decimal.new(0),
    device_miles_deduction_cents: 0,
    device_miles_deduction_cents_engaged: 0,
    device_miles_engaged: Decimal.new(0),
    device_miles_quality_percent: Decimal.new(0),
    duration_seconds: 0,
    duration_seconds_engaged: 0,
    platform_miles: Decimal.new(0),
    platform_miles_deduction_cents: 0,
    platform_miles_deduction_cents_engaged: 0,
    platform_miles_engaged: Decimal.new(0),
    platform_miles_quality_percent: Decimal.new(0),
    selected_miles: Decimal.new(0),
    selected_miles_deduction_cents: 0,
    selected_miles_deduction_cents_engaged: 0,
    selected_miles_engaged: Decimal.new(0),
    selected_miles_quality_percent: Decimal.new(0),
    user_id: nil
  }

  def render("summary.json", %{
        data: %{
          work_date_start: work_date_start,
          work_date_end: work_date_end,
          time_and_mileage: time_and_mileage,
          job_earnings: job_earnings,
          other_earnings: other_earnings,
          expenses: expenses
        }
      }) do
    by_employer = combine_earnings(job_earnings, other_earnings)

    earnings_summary =
      by_employer
      |> summarize_earnings()
      |> Map.merge(time_and_mileage || @time_and_mileage_template)
      |> Map.put(:by_employer, by_employer)
      |> Map.put(:expenses, expenses)

    %{
      data: render_summary(earnings_summary, work_date_start, work_date_end)
    }
  end

  defp render_activity(activity) do
    %{
      activity_id: activity.id,
      activity_key: activity.activity_id,
      employer: activity.employer,
      employer_service: activity.employer_service,
      service_class: activity.service_class,
      earning_type: activity.earning_type,
      timestamp_work_start: activity.timestamp_work_start,
      timestamp_work_end: activity.timestamp_work_end,
      timestamp_start: activity.timestamp_start,
      timestamp_end: activity.timestamp_end,
      timestamp_request: activity.timestamp_request,
      timestamp_accept: activity.timestamp_accept,
      timestamp_cancel: activity.timestamp_cancel,
      timestamp_pickup: activity.timestamp_pickup,
      timestamp_dropoff: activity.timestamp_dropoff,
      timestamp_shift_start: activity.timestamp_shift_start,
      timestamp_shift_end: activity.timestamp_shift_end,
      is_pool: activity.is_pool,
      is_rush: activity.is_rush,
      is_surge: activity.is_surge,
      income_rate_hour_cents: activity.income_rate_hour_cents,
      income_rate_mile_cents: activity.income_rate_mile_cents,
      distance: activity.distance,
      distance_unit: activity.distance_unit,
      duration_seconds: activity.duration_seconds,
      timezone: activity.timezone,
      charges_fees_cents: activity.charges_fees_cents,
      charges_taxes_cents: activity.charges_taxes_cents,
      charges_total_cents: activity.charges_total_cents,
      working_day_start: activity.working_day_start,
      working_day_end: activity.working_day_end,
      tasks_total: activity.tasks_total,
      earnings_pay_cents: activity.earnings_pay_cents,
      earnings_tip_cents: activity.earnings_tip_cents,
      earnings_bonus_cents: activity.earnings_bonus_cents,
      earnings_total_cents: activity.earnings_total_cents
    }
  end

  defp render_timespan(timespan) do
    model = %{
      timespan_id: timespan.id,
      start_time: timespan.start_time,
      end_time: timespan.end_time,
      work_date: timespan.work_date,
      shift_ids: Map.get(timespan, :shift_ids),
      duration_seconds: timespan.duration_seconds,
      duration_seconds_engaged: timespan.duration_seconds_engaged,
      duration_seconds_not_engaged:
        MathUtil.subtract(timespan.duration_seconds, timespan.duration_seconds_engaged),
      selected_miles_quality_percent: timespan.selected_miles_quality_percent,
      selected_miles: timespan.selected_miles,
      selected_miles_deduction_cents: timespan.selected_miles_deduction_cents,
      selected_miles_engaged: timespan.selected_miles_engaged,
      selected_miles_deduction_cents_engaged: timespan.selected_miles_deduction_cents_engaged,
      selected_miles_not_engaged:
        MathUtil.subtract(timespan.selected_miles, timespan.selected_miles_engaged),
      selected_miles_deduction_cents_not_engaged:
        MathUtil.subtract(
          timespan.selected_miles_deduction_cents,
          timespan.selected_miles_deduction_cents_engaged
        ),
      device_miles_quality_percent: timespan.device_miles_quality_percent,
      device_miles: timespan.device_miles,
      device_miles_deduction_cents: timespan.device_miles_deduction_cents,
      device_miles_engaged: timespan.device_miles_engaged,
      device_miles_deduction_cents_engaged: timespan.device_miles_deduction_cents_engaged,
      device_miles_not_engaged:
        MathUtil.subtract(timespan.device_miles, timespan.device_miles_engaged),
      device_miles_deduction_cents_not_engaged:
        MathUtil.subtract(
          timespan.device_miles_deduction_cents,
          timespan.device_miles_deduction_cents_engaged
        ),
      platform_miles_quality_percent: timespan.platform_miles_quality_percent,
      platform_miles: timespan.platform_miles,
      platform_miles_deduction_cents: timespan.platform_miles_deduction_cents,
      platform_miles_engaged: timespan.platform_miles_engaged,
      platform_miles_deduction_cents_engaged: timespan.platform_miles_deduction_cents_engaged,
      platform_miles_not_engaged:
        MathUtil.subtract(timespan.platform_miles, timespan.platform_miles_engaged),
      platform_miles_deduction_cents_not_engaged:
        MathUtil.subtract(
          timespan.platform_miles_deduction_cents,
          timespan.platform_miles_deduction_cents_engaged
        )
    }

    allocations = Map.get(timespan, :allocations)

    if is_nil(allocations) do
      model
    else
      model
      |> Map.put(:allocations, Enum.map(allocations, fn a -> render_allocation(a) end))
    end
  end

  defp render_allocation(allocation) do
    %{
      allocation_id: allocation.id,
      start_time: allocation.start_time,
      end_time: allocation.end_time,
      duration_seconds: allocation.duration_seconds,
      activity_extends_before: Map.get(allocation, :activity_extends_before),
      activity_extends_after: Map.get(allocation, :activity_extends_after),
      activity_coverage_percent: Map.get(allocation, :activity_coverage_percent),
      device_miles: Map.get(allocation, :device_miles),
      device_miles_quality_percent: Map.get(allocation, :device_miles_quality_percent),
      platform_miles: Map.get(allocation, :platform_miles_per_second)
    }
    |> Map.merge(render_activity_overview(allocation, Map.get(allocation, :activity)))
  end

  defp render_activity_overview(_allocation, nil) do
    %{}
  end

  defp render_activity_overview(allocation, activity) do
    alloc_percent = Map.get(allocation, :activity_coverage_percent, 1.0)

    %{
      activity_id: activity.id,
      employer: activity.employer,
      employer_service: activity.employer_service,
      service_class: activity.service_class,
      timestamp_work_start: activity.timestamp_work_start,
      timestamp_work_end: activity.timestamp_work_end,
      earnings_pay_cents: MathUtil.mult(activity.earnings_pay_cents, alloc_percent),
      earnings_tip_cents: MathUtil.mult(activity.earnings_tip_cents, alloc_percent),
      earnings_bonus_cents: MathUtil.mult(activity.earnings_bonus_cents, alloc_percent),
      earnings_total_cents: MathUtil.mult(activity.earnings_total_cents, alloc_percent)
    }
  end

  @earnings_model_template %{
    duration_seconds: 0,
    device_miles: Decimal.new(0),
    device_miles_deduction_cents: 0,
    platform_miles: 0,
    job_count_days: 0,
    job_count: 0,
    job_count_tasks: 0,
    job_earnings_pay_cents: 0,
    job_earnings_tip_cents: 0,
    job_earnings_bonus_cents: 0,
    job_earnings_total_cents: 0,
    other_count_activities: 0,
    other_count_days: 0,
    other_earnings_pay_cents: 0,
    other_earnings_tip_cents: 0,
    other_earnings_bonus_cents: 0,
    other_earnings_total_cents: 0
  }

  # Combines two sets of employer summaried earnings into a single array of earnings by employer
  defp combine_earnings(job_earnings, other_earnings) do
    (List.wrap(job_earnings) ++ List.wrap(other_earnings))
    |> Enum.reduce(%{}, fn earnings, model ->
      employer = Map.get(earnings, :employer)

      if is_nil(employer) do
        model
      else
        earnings =
          Map.get(model, employer, @earnings_model_template)
          |> Map.merge(earnings)

        Map.put(model, employer, earnings)
      end
    end)
    |> Map.values()
  end

  # sums up earnings values
  defp summarize_earnings(earnings) do
    Enum.reduce(earnings, @earnings_model_template, fn e, model ->
      %{
        job_count: model.job_count + to_integer(e.job_count),
        job_count_tasks: model.job_count_tasks + to_integer(e.job_count_tasks),
        job_earnings_bonus_cents:
          model.job_earnings_bonus_cents + to_integer(e.job_earnings_bonus_cents),
        job_earnings_pay_cents:
          model.job_earnings_pay_cents + to_integer(e.job_earnings_pay_cents),
        job_earnings_tip_cents:
          model.job_earnings_tip_cents + to_integer(e.job_earnings_tip_cents),
        job_earnings_total_cents:
          model.job_earnings_total_cents + to_integer(e.job_earnings_total_cents),
        other_count_activities:
          model.other_count_activities + to_integer(e.other_count_activities),
        other_earnings_bonus_cents:
          model.other_earnings_bonus_cents + to_integer(e.other_earnings_bonus_cents),
        other_earnings_pay_cents:
          model.other_earnings_pay_cents + to_integer(e.other_earnings_pay_cents),
        other_earnings_tip_cents:
          model.other_earnings_tip_cents + to_integer(e.other_earnings_tip_cents),
        other_earnings_total_cents:
          model.other_earnings_total_cents + to_integer(e.other_earnings_total_cents)
      }
    end)
  end

  defp render_summary(model, work_date_start, work_date_end) do
    result = %{
      work_date_start: work_date_start,
      work_date_end: work_date_end,
      by_employer:
        Enum.map(model.by_employer, fn emp_metric -> render_employer_metric(emp_metric) end),
      cents_earnings_gross:
        to_integer(model.job_earnings_total_cents) + to_integer(model.other_earnings_total_cents),
      cents_expenses_deductible: to_integer(model.expenses),
      cents_expenses_mileage: to_integer(model.selected_miles_deduction_cents),
      cents_pay:
        to_integer(model.job_earnings_pay_cents) + to_integer(model.other_earnings_pay_cents),
      cents_promotion:
        to_integer(model.job_earnings_bonus_cents) + to_integer(model.other_earnings_bonus_cents),
      cents_tip:
        to_integer(model.job_earnings_tip_cents) + to_integer(model.other_earnings_tip_cents),
      miles_total: round_number(model.selected_miles),
      seconds_p3: to_integer(model.duration_seconds_engaged),
      seconds_total: to_integer(model.duration_seconds),
      tasks_total: to_integer(model.job_count_tasks)
    }

    result =
      Map.put(
        result,
        :cents_earnings_net,
        to_integer(result.cents_earnings_gross) - to_integer(result.cents_expenses_mileage) -
          to_integer(result.cents_expenses_deductible)
      )

    if result.seconds_total > 0 do
      hourly_gross =
        (to_integer(result.cents_earnings_gross) / result.seconds_total)
        |> Decimal.from_float()
        |> Decimal.mult(60)
        |> Decimal.mult(60)

      hourly_net =
        (to_integer(result.cents_earnings_net) / result.seconds_total)
        |> Decimal.from_float()
        |> Decimal.mult(60)
        |> Decimal.mult(60)

      result
      |> Map.put(:cents_average_hourly_gross, to_integer(hourly_gross))
      |> Map.put(:cents_average_hourly_net, to_integer(hourly_net))
    else
      result
      |> Map.put(:cents_average_hourly_gross, 0)
      |> Map.put(:cents_average_hourly_net, 0)
    end
  end

  defp render_employer_metric(emp_metric) do
    %{
      employer: emp_metric.employer,
      cents_pay:
        to_integer(emp_metric.job_earnings_pay_cents) +
          to_integer(emp_metric.other_earnings_pay_cents),
      cents_promotion:
        to_integer(emp_metric.job_earnings_bonus_cents) +
          to_integer(emp_metric.other_earnings_bonus_cents),
      cents_tip:
        to_integer(emp_metric.job_earnings_tip_cents) +
          to_integer(emp_metric.other_earnings_tip_cents),
      seconds_p3: to_integer(emp_metric.duration_seconds),
      seconds_total: to_integer(emp_metric.duration_seconds),
      tasks_total: to_integer(emp_metric.job_count_tasks)
    }
  end

  defp to_integer(nil), do: 0

  defp to_integer(number) when is_float(number) do
    to_integer(Decimal.from_float(number))
  end

  defp to_integer(%Decimal{} = number), do: Decimal.round(number) |> Decimal.to_integer()

  defp to_integer(number) when is_integer(number),
    do: number

  defp round_number(nil), do: 0

  defp round_number(number), do: Decimal.round(number, 2) |> Decimal.to_float()
end
