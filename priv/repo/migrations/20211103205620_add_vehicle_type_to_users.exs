defmodule DriversSeatCoop.Repo.Migrations.AddVehicleTypeToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:vehicle_type, :text)
    end
  end
end
