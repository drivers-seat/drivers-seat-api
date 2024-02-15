defmodule DriversSeatCoop.Repo.Migrations.CreateRegionsTables do
  use Ecto.Migration

  def change do
    create table(:region_state, primary_key: false) do
      add(:id, :integer, null: false, primary_key: true)
      add(:name, :citext, null: false)
      add(:abbrv, :citext, null: false)
      add(:geometry, :geometry, null: false)
    end

    create unique_index(:region_state, [:name])
    create unique_index(:region_state, [:abbrv])

    create table(:region_metro_area, primary_key: false) do
      add(:id, :integer, null: false, primary_key: true)
      add(:name, :citext, null: false)
      add(:full_name, :citext, null: false)
      add(:geometry, :geometry, null: false)

      add(:count_workers, :integer, null: true)
      add(:hourly_pay_stat_coverage_percent, :decimal, null: true)
      add(:hourly_pay_stat_coverage_percent_rideshare, :decimal, null: true)
      add(:hourly_pay_stat_coverage_percent_delivery, :decimal, null: true)
      add(:hourly_pay_stat_coverage_count_workers, :integer, null: true)
      add(:hourly_pay_stat_coverage_count_workers_rideshare, :integer, null: true)
      add(:hourly_pay_stat_coverage_count_workers_delivery, :integer, null: true)
      add(:hourly_pay_stat_coverage_count_employers, :integer, null: true)
      add(:hourly_pay_stat_coverage_count_employers_rideshare, :integer, null: true)
      add(:hourly_pay_stat_coverage_count_employers_delivery, :integer, null: true)
      add(:hourly_pay_stat_coverage_count_jobs, :integer, null: true)
      add(:hourly_pay_stat_coverage_count_jobs_rideshare, :integer, null: true)
      add(:hourly_pay_stat_coverage_count_jobs_delivery, :integer, null: true)
      add(:hourly_pay_stat_coverage_count_tasks, :integer, null: true)
      add(:hourly_pay_stat_coverage_count_tasks_rideshare, :integer, null: true)
      add(:hourly_pay_stat_coverage_count_tasks_delivery, :integer, null: true)
    end

    create unique_index(:region_metro_area, [:name])
    create unique_index(:region_metro_area, [:full_name])

    create table(:region_county, primary_key: false) do
      add(:id, :integer, null: false, primary_key: true)
      add(:name, :citext, null: false)
      add(:region_id_state, references(:region_state, on_delete: :nothing), null: false)
      add(:geometry, :geometry, null: false)
    end

    create unique_index(:region_county, [:region_id_state, :name])

    create table(:region_postal_code, primary_key: false) do
      add(:id, :integer, null: false, primary_key: true)
      add(:postal_code, :citext, null: false)
      add(:region_id_metro_area, references(:region_metro_area, on_delete: :nothing), null: true)
      add(:region_id_state, references(:region_state, on_delete: :nothing), null: false)
      add(:region_id_county, references(:region_county, on_delete: :nothing), null: false)
      add(:geometry, :geometry, null: false)
    end

    create unique_index(:region_postal_code, [:postal_code])
  end
end
