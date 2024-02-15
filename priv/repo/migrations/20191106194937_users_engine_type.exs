defmodule DriversSeatCoop.Repo.Migrations.UsersEngineType do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :engine_type, :text
    end
  end
end
