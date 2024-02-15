defmodule DriversSeatCoop.Repo.Migrations.CreatePoints do
  use Ecto.Migration

  def change do
    drop(index(:trip_points, :trip_id_recorded_at))
    rename(table(:trip_points), to: table(:points))

    alter table(:points) do
      add :status, :text, null: false
      modify :trip_id, references(:trips, on_delete: :nothing), null: true
      add :user_id, references(:users, on_delete: :nothing), null: false
    end

    create unique_index(:points, [:user_id, :recorded_at], name: :points_user_id_recorded_at_index)
  end
end
