defmodule DriversSeatCoop.Repo.Migrations.RemoveShiftIdFromPointsTable do
  use Ecto.Migration

  def change do
    alter table(:points) do
      remove(:shift_id)
    end
  end
end
