defmodule DriversSeatCoop.Repo.Migrations.CreateArgyleAccountTable do
  use Ecto.Migration

  def change do
    create table(:argyle_account) do
      add :argyle_id, :text, null: false
      add :userToken, :text
      add :user_id, references(:users, on_delete: :nothing), null: false

      timestamps()
    end
  end
end
