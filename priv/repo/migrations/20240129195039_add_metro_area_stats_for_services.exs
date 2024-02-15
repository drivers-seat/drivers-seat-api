defmodule DriversSeatCoop.Repo.Migrations.AddMetroAreaStatsForServices do
  use Ecto.Migration

  def change do
    alter table(:region_metro_area) do
      add(:hourly_pay_stat_coverage_percent_services, :decimal, null: true)
      add(:hourly_pay_stat_coverage_count_workers_services, :integer, null: true)
      add(:hourly_pay_stat_coverage_count_employers_services, :integer, null: true)
      add(:hourly_pay_stat_coverage_count_jobs_services, :integer, null: true)
      add(:hourly_pay_stat_coverage_count_tasks_services, :integer, null: true)
    end
  end
end
