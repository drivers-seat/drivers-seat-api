defmodule DriversSeatCoop.Repo.Migrations.AddScheduledShifts do
  use Ecto.Migration

  def change do
    create table(:scheduled_shifts) do
      add(:user_id, references(:users, on_delete: :nothing), null: false)
      add(:start_day_of_week, :integer, null: false)
      add(:start_time_local, :time, null: false)
      add(:duration_minutes, :integer, null: false)
      timestamps()
    end

    create(index(:scheduled_shifts, [:user_id]))

    alter table(:users) do
      add(:remind_shift_start, :boolean, default: false)
      add(:remind_shift_end, :boolean, default: false)
    end
  end
end
