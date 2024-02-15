defmodule DriversSeatCoop.Repo.Migrations.Passwords do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :password_hash, :text
      modify :identifier, :text, null: true
    end
  end
end
