defmodule DriversSeatCoop.Repo.Migrations.RemoveTripIdFromPoints do
  use Ecto.Migration

  def change do
    alter table(:points) do
      remove(:trip_id)
    end
  end
end
