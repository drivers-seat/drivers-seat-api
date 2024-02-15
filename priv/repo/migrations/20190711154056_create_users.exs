defmodule DriversSeatCoop.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :text
      add :name, :text
      add :identifier, :text, null: false

      timestamps()
    end

    create unique_index(:users, [:identifier], name: :users_identifier_index)
    create unique_index(:users, ["(lower(email))"], name: :users_email_lower_index)
  end
end
