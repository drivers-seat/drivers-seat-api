defmodule DriversSeatCoop.Repo.Migrations.AddSecondsGpsCoverageColumn do
  use Ecto.Migration

  def change do
    alter table(:segments) do
      add(:seconds_gps_coverage, :decimal)
    end
  end
end
