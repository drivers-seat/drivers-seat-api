defmodule DriversSeatCoop.Repo.Migrations.CreateActivitesTable do
  use Ecto.Migration

  def change do
    create table(:activities) do
      add :activity_id, :text, null: false
      add :user_id, references(:users, on_delete: :nothing), null: false

      timestamps()
    end
  end
end
