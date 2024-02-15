defmodule DriversSeatCoop.Repo.Migrations.UsersRole do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :role, :text
    end
  end
end
