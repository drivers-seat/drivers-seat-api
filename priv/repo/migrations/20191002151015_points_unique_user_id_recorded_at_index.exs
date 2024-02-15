defmodule DriversSeatCoop.Repo.Migrations.PointsUniqueUserIdRecordedAtIndex do
  use Ecto.Migration

  def change do
    create unique_index(:points, [:user_id, :recorded_at], name: :points_user_id_recorded_at_index)
  end
end
