defmodule DriversSeatCoop.Repo.Migrations.AddDeletedToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :deleted, :boolean, default: false
    end
  end
end
