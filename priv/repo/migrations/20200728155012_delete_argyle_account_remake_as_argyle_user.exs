defmodule DriversSeatCoop.Repo.Migrations.DeleteArgyleAccountRemakeAsArgyleUser do
  use Ecto.Migration

  def change do
    drop_if_exists table(:argyle_account)

    create table(:argyle_user) do
      add :argyle_id, :text, null: false
      add :user_token, :text
      add :user_id, references(:users, on_delete: :nothing), null: false
      add :accounts, :jsonb

      timestamps()
    end
  end
end
