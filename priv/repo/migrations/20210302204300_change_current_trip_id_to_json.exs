defmodule DriversSeatCoop.Repo.Migrations.ChangeCurrentTripIdToJson do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove :current_trip_id
      add :current_trip, :jsonb
    end
  end
end
