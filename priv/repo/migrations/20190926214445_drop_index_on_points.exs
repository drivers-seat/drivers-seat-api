defmodule DriversSeatCoop.Repo.Migrations.DropIndexOnPoints do
  use Ecto.Migration

  def change do
    drop unique_index(:points, [:user_id, :recorded_at], name: :points_user_id_recorded_at_index)
  end
end
