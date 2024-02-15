defmodule DriversSeatCoop.Repo.Migrations.CaptureLocationSvcConfigStatus do
  use Ecto.Migration

  def change do
    alter table(:devices) do
      add(:location_tracking_config_status, :ciText)
    end
  end
end
