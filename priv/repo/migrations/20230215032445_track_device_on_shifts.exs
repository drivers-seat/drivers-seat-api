defmodule DriversSeatCoop.Repo.Migrations.TrackDeviceOnShifts do
  use Ecto.Migration

  def change do
    alter table(:shifts) do
      add(:device_id, references(:devices, on_delete: :nothing))
    end
  end
end
