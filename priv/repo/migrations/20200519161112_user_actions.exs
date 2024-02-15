defmodule DriversSeatCoop.Repo.Migrations.UserActions do
  use Ecto.Migration

  def change do
    create table(:user_actions) do
      add :user_id, references(:users)
      add :event, :text
      add :recorded_at, :naive_datetime

      timestamps()
    end

    create index(:user_actions, [:user_id, :event, "recorded_at DESC"])
  end
end
