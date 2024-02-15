defmodule DriversSeatCoopWeb.MetroAreaView do
  use DriversSeatCoopWeb, :view
  alias DriversSeatCoopWeb.MetroAreaView

  def render("index.json", %{metro_areas: metro_areas}) do
    %{data: render_many(metro_areas, MetroAreaView, "metro_area.json")}
  end

  def render("metro_area.json", %{metro_area: metro_area}) do
    %{
      id: metro_area.id,
      name: metro_area.name,
      hourly_pay_stat_coverage_percent: metro_area.hourly_pay_stat_coverage_percent,
      hourly_pay_stat_coverage_percent_rideshare:
        metro_area.hourly_pay_stat_coverage_percent_rideshare,
      hourly_pay_stat_coverage_percent_delivery:
        metro_area.hourly_pay_stat_coverage_percent_delivery,
      hourly_pay_stat_coverage_count_workers: metro_area.hourly_pay_stat_coverage_count_workers,
      hourly_pay_stat_coverage_count_workers_rideshare:
        metro_area.hourly_pay_stat_coverage_count_workers_rideshare,
      hourly_pay_stat_coverage_count_workers_delivery:
        metro_area.hourly_pay_stat_coverage_count_workers_delivery,
      hourly_pay_stat_coverage_count_employers:
        metro_area.hourly_pay_stat_coverage_count_employers,
      hourly_pay_stat_coverage_count_employers_rideshare:
        metro_area.hourly_pay_stat_coverage_count_employers_rideshare,
      hourly_pay_stat_coverage_count_employers_delivery:
        metro_area.hourly_pay_stat_coverage_count_employers_delivery,
      hourly_pay_stat_coverage_count_jobs: metro_area.hourly_pay_stat_coverage_count_jobs,
      hourly_pay_stat_coverage_count_jobs_rideshare:
        metro_area.hourly_pay_stat_coverage_count_jobs_rideshare,
      hourly_pay_stat_coverage_count_jobs_delivery:
        metro_area.hourly_pay_stat_coverage_count_jobs_delivery,
      hourly_pay_stat_coverage_count_tasks: metro_area.hourly_pay_stat_coverage_count_tasks,
      hourly_pay_stat_coverage_count_tasks_rideshare:
        metro_area.hourly_pay_stat_coverage_count_tasks_rideshare,
      hourly_pay_stat_coverage_count_tasks_delivery:
        metro_area.hourly_pay_stat_coverage_count_tasks_delivery
    }
  end
end
