defmodule DriversSeatCoop.Repo.Migrations.AddMilesP3GpsColumn do
  use Ecto.Migration

  def change do
    alter table(:segments) do
      add(:miles_p3_gps, :decimal)
    end
  end
end
