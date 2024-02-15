defmodule DriversSeatCoop.Repo.Migrations.UserContactPermission do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :contact_permission, :boolean
    end
  end
end
