defmodule DriversSeatCoop.Repo.Migrations.AddActivityDeletedColumn do
  use Ecto.Migration

  def change do
    alter table(:activities) do
      add(:deleted, :boolean, default: false)
    end
  end
end
