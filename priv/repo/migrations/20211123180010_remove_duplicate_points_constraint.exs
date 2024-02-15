defmodule DriversSeatCoop.Repo.Migrations.RemoveDuplicatePointsConstraint do
  use Ecto.Migration

  def change do
    # this is a duplicate constraint that was probably created by the rename in
    # 20190711205559_create_points. the table used to be called "trip_points"
    # before it was renamed to just "points"
    drop(constraint(:points, "trip_points_trip_id_fkey"))
  end
end
