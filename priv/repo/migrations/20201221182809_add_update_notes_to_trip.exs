defmodule DriversSeatCoop.Repo.Migrations.AddUpdateNotesToTrip do
  use Ecto.Migration

  def change do
    alter table(:trips) do
      add :updated_notes, :jsonb
    end
  end
end
