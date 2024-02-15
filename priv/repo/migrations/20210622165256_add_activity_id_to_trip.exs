defmodule DriversSeatCoop.Repo.Migrations.AddActivityIdToTrip do
  use Ecto.Migration

  def change do
    alter table(:trips) do
      add :activity_id, references(:activities, on_delete: :nothing)
    end
  end
end
