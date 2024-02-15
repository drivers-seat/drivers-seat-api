defmodule DriversSeatCoop.Repo.Migrations.RemoveUserIdentifierField do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove(:identifier)
    end
  end
end
