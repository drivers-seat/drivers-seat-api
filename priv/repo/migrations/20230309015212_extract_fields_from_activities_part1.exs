defmodule DriversSeatCoop.Repo.Migrations.ExtractFieldsFromActivitiesPart1 do
  use Ecto.Migration

  def change do
    alter table(:activities) do
      add(:working_day_start, :date, null: true)
      add(:working_day_end, :date, null: true)
      add(:service_class, :citext, null: true)
      add(:employer, :citext, null: true)
      add(:employer_service, :citext, null: true)
      add(:data_partner, :citext, null: true)
      add(:earning_type, :citext, null: true)
      add(:currency, :citext, null: true)

      add(:income_rate_hour_cents, :integer, null: true)
      add(:income_rate_mile_cents, :integer, null: true)

      add(:status, :citext, null: true)

      add(:distance, :decimal, null: true)
      add(:distance_unit, :citext, null: true)

      add(:duration_seconds, :integer, null: true)

      add(:timezone, :citext, null: true)
      add(:timestamp_start, :utc_datetime, null: true)
      add(:timestamp_end, :utc_datetime, null: true)
      add(:timestamp_request, :utc_datetime, null: true)
      add(:timestamp_accept, :utc_datetime, null: true)
      add(:timestamp_cancel, :utc_datetime, null: true)
      add(:timestamp_pickup, :utc_datetime, null: true)
      add(:timestamp_dropoff, :utc_datetime, null: true)
      add(:timestamp_shift_start, :utc_datetime, null: true)
      add(:timestamp_shift_end, :utc_datetime, null: true)

      add(:timestamp_work_start, :utc_datetime, null: true)
      add(:timestamp_work_end, :utc_datetime, null: true)

      add(:is_pool, :boolean, null: true)
      add(:is_rush, :boolean, null: true)
      add(:is_surge, :boolean, null: true)

      add(:start_location_geometry, :geometry, null: true)
      add(:start_location_address, :citext, null: true)

      add(:end_location_geometry, :geometry, null: true)
      add(:end_location_address, :citext, null: true)

      add(:earnings_pay_cents, :integer, null: true)
      add(:earnings_tip_cents, :integer, null: true)
      add(:earnings_bonus_cents, :integer, null: true)
      add(:earnings_total_cents, :integer, null: true)

      add(:charges_fees_cents, :integer, null: true)
      add(:charges_taxes_cents, :integer, null: true)
      add(:charges_total_cents, :integer, null: true)

      add(:tasks_total, :integer, null: true)
    end
  end
end
