defmodule DriversSeatCoop.Repo.Migrations.RemoveCurrentTrip do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove(:current_trip)
    end
  end
end
