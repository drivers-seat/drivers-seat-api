defmodule DriversSeatCoop.Repo.Migrations.PointsTripIdIndex do
  use Ecto.Migration

  def change do
    create index(:points, ["trip_id", "recorded_at DESC"])
  end
end
