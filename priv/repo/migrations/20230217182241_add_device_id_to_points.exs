defmodule DriversSeatCoop.Repo.Migrations.AddDeviceIdToPoints do
  use Ecto.Migration

  def change do
    alter table(:points) do
      add(:device_id, references(:devices, on_delete: :nothing))
    end
  end
end
