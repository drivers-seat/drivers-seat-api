defmodule DriversSeatCoop.Repo.Migrations.ReplaceSegmentsWithTimespansAndAllocations do
  use Ecto.Migration
  alias DriversSeatCoop.Earnings.TimespanCalcMethod

  def change do
    TimespanCalcMethod.create_type()

    create table(:timespans) do
      add(:user_id, references(:users, on_delete: :nothing), null: false)
      add(:work_date, :date, null: false)
      add(:calc_method, :timespan_calc_method, null: false)
      add(:start_time, :utc_datetime, null: false)
      add(:end_time, :utc_datetime, null: false)
      add(:duration_seconds, :integer, null: false)
      add(:duration_seconds_engaged, :integer, null: false)
      add(:shift_ids, {:array, :integer}, null: true)
      add(:device_miles, :decimal, null: true)
      add(:device_miles_engaged, :decimal, null: true)
      add(:device_miles_deduction_cents, :integer, null: true)
      add(:device_miles_deduction_cents_engaged, :integer, null: true)
      add(:device_miles_quality_percent, :decimal, null: true)
      add(:platform_miles, :decimal, null: true)
      add(:platform_miles_engaged, :decimal, null: true)
      add(:platform_miles_deduction_cents, :integer, null: true)
      add(:platform_miles_deduction_cents_engaged, :integer, null: true)
      add(:platform_miles_quality_percent, :decimal, null: true)
      timestamps()
    end

    create unique_index(:timespans, [:user_id, :calc_method, :start_time],
             name: :timespans_user_calc_method_start_time_key
           )

    create index(:timespans, [:user_id, :calc_method, :work_date],
             name: :timespans_user_calc_method_work_date_index
           )

    create table(:timespan_allocations) do
      add(:timespan_id, references(:timespans, on_delete: :nothing), null: false)
      add(:start_time, :utc_datetime, null: false)
      add(:end_time, :utc_datetime, null: false)
      add(:activity_id, references(:activities, on_delete: :nothing), null: true)
      add(:duration_seconds, :integer, null: false)
      add(:activity_extends_before, :boolean, null: true)
      add(:activity_extends_after, :boolean, null: true)
      add(:activity_coverage_percent, :decimal, null: true)
      add(:device_miles, :decimal, null: true)
      add(:device_miles_deduction_cents, :integer, null: true)
      add(:device_miles_quality_percent, :decimal, null: true)
      add(:platform_miles, :decimal, null: true)
      add(:platform_miles_per_second, :decimal, null: true)
      timestamps()
    end

    create unique_index(:timespan_allocations, [:timespan_id, :start_time, :activity_id],
             name: :timespan_allocations_timespan_start_time_activity_id_key
           )

    create index(:timespan_allocations, [:activity_id],
             name: :timespan_allocations_activity_id_index
           )
  end
end
