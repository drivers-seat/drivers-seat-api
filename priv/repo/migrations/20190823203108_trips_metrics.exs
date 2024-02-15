defmodule DriversSeatCoop.Repo.Migrations.TripsMetrics do
  use Ecto.Migration

  def change do
    alter table(:trips) do
      add :metrics, :map
    end
  end
end
