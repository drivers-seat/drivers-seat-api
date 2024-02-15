defmodule DriversSeatCoop.Repo.Migrations.CaptureActivityHourBreakdown do
  use Ecto.Migration

  def change do
    create table(:activity_hours) do
      add(:activity_id, references(:activities, on_delete: :nothing), null: false)
      add(:date_local, :date, null: false)
      add(:week_start_date, :date, null: false)
      add(:day_of_week, :integer, null: false)
      add(:hour_local, :time, null: false)
      add(:percent_of_activity, :float, null: false)
      add(:duration_seconds, :integer, null: false)
      add(:earnings_total_cents, :integer, null: false)
      add(:distance_miles, :decimal, null: true)
      add(:deduction_mileage_cents, :integer, null: true)
      timestamps()
    end

    create unique_index(:activity_hours, [:activity_id, :date_local, :hour_local],
             name: :activity_hours_ak
           )

    # CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS activities_working_day_start_id_user_id ON activities(working_day_start, id, user_id)

    create_if_not_exists(
      unique_index(:activities, [:working_day_start, :id, :user_id],
        name: :activities_working_day_start_id_user_id
      )
    )
  end
end
