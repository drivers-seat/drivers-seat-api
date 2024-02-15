defmodule DriversSeatCoop.Repo.Migrations.PointsAccuracy do
  use Ecto.Migration

  def change do
    alter table(:points) do
      add :accuracy, :float
    end
  end
end
