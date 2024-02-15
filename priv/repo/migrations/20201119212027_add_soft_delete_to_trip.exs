defmodule DriversSeatCoop.Repo.Migrations.AddSoftDeleteToTrip do
  use Ecto.Migration

  def change do
    alter table(:trips) do
      add :deleted, :boolean, null: false, default: false
    end
  end
end
