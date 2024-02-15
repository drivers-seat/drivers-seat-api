defmodule DriversSeatCoop.Repo.Migrations.CreateShiftTable do
  use Ecto.Migration

  def change do
    create table(:shifts) do
      add :user_id, references(:users, on_delete: :nothing), null: false
      add :start_time, :naive_datetime_usec
      add :end_time, :naive_datetime_usec
      add :needs_argyle_analysis, :boolean, default: false

      timestamps()
    end

    alter table(:points) do
      add :shift_id, references(:shifts, on_delete: :nothing)
    end

    alter table(:trips) do
      add :shift_id, references(:shifts, on_delete: :nothing)
    end
  end
end
