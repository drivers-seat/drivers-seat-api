defmodule DriversSeatCoop.Repo.Migrations.PointsExtraFields do
  use Ecto.Migration

  def change do
    alter table(:points) do
      add :heading, :float
      add :speed, :float
      add :altitude, :float
      add :battery_level, :float
      add :battery_is_charging, :boolean
      add :activity_type, :text
      add :activity_confidence, :float
      add :is_moving, :boolean
    end
  end
end
