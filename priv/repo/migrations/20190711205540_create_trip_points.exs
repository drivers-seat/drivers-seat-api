defmodule DriversSeatCoop.Repo.Migrations.CreateTripPoints do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS postgis"

    create table(:trip_points) do
      add :geometry, :geometry
      add :recorded_at, :naive_datetime_usec
      add :trip_id, references(:trips, on_delete: :nothing), null: false

      timestamps()
    end

    create unique_index(:trip_points, [:trip_id, :recorded_at],
             name: :trip_points_trip_id_recorded_at_index
           )
  end
end
