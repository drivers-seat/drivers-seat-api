defmodule DriversSeatCoop.Repo.Migrations.StoreShiftChanges do
  use Ecto.Migration

  def change do
    alter table(:shifts) do
      add(:deleted, :boolean, default: false)
    end
  end
end
