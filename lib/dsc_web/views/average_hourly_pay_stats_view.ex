defmodule DriversSeatCoopWeb.AverageHourlyPayStatsView do
  use DriversSeatCoopWeb, :view

  def render("summary.json", %{stats: stats}) do
    %{
      data:
        Enum.map(stats, fn stat ->
          %{
            metro_area_id: stat.metro_area_id,
            for_week: stat.week_start_date,
            day_of_week: stat.day_of_week,
            hour_of_day: stat.hour_local.hour,
            cents_avg_hourly_pay: stat.earnings_avg_hr_cents,
            cents_avg_hourly_pay_with_mileage: stat.earnings_avg_hr_cents_with_mileage,
            best_employer: %{
              # this is correct
              employer_id: stat.best_employer.employer_service_class_id,
              cents_avg_hourly_pay: stat.best_employer.earnings_avg_hr_cents,
              cents_avg_hourly_pay_with_mileage:
                stat.best_employer.earnings_avg_hr_cents_with_mileage,
              count_jobs: stat.best_employer.count_activities,
              count_tasks: stat.best_employer.count_tasks,
              count_workers: stat.best_employer.count_users
            },
            best_employer_with_mileage: %{
              # this is correct
              employer_id: stat.best_employer_with_mileage.employer_service_class_id,
              cents_avg_hourly_pay: stat.best_employer_with_mileage.earnings_avg_hr_cents,
              cents_avg_hourly_pay_with_mileage:
                stat.best_employer_with_mileage.earnings_avg_hr_cents_with_mileage,
              count_jobs: stat.best_employer_with_mileage.count_activities,
              count_tasks: stat.best_employer_with_mileage.count_tasks,
              count_workers: stat.best_employer_with_mileage.count_users
            },
            coverage: %{
              count_employers: stat.coverage.count_employers,
              count_service_classes: stat.coverage.count_service_classes,
              count_jobs: stat.coverage.count_activities,
              count_tasks: stat.coverage.count_tasks,
              seconds_total: stat.coverage.duration_seconds,
              cents_earnings_total: stat.coverage.earnings_total_cents,
              cents_deduction_mileage_total: stat.coverage.deduction_mileage_cents,
              miles_reported_total: stat.coverage.distance_miles
            }
          }
        end)
    }
  end

  def render("trend.json", %{stats: stats}) do
    %{
      data:
        Enum.map(stats, fn stat ->
          %{
            for_week: stat.week_start_date,
            # this is correct
            employer_id: stat.employer_service_class_id,
            service_class_id: stat.service_class_id,
            count_jobs: stat.count_activities,
            count_tasks: stat.count_tasks,
            count_workers: stat.count_users,
            count_weeks: stat.count_week_samples,
            seconds_total: stat.duration_seconds,
            cents_earnings_total: stat.earnings_total_cents,
            cents_deduction_mileage_total: stat.deduction_mileage_cents,
            miles_reported_total: stat.distance_miles,
            cents_avg_hourly_pay: stat.earnings_avg_hr_cents,
            cents_avg_hourly_pay_with_mileage: stat.earnings_avg_hr_cents_with_mileage
          }
        end)
    }
  end
end
