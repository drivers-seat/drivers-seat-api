defmodule DriversSeatCoop.Repo.Migrations.CreateDailyStats do
  use Ecto.Migration

  def change do
    create table(:daily_stats) do
      add :metrics, :map
      add :date, :date
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create unique_index(:daily_stats, ["user_id", "date DESC"])
  end
end
