defmodule DriversSeatCoop.Repo.Migrations.AddIsBetaToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :is_beta, :boolean
    end
  end
end
