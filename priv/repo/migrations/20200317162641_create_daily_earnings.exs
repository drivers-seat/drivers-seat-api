defmodule DriversSeatCoop.Repo.Migrations.CreateDailyEarnings do
  use Ecto.Migration

  def change do
    create table(:daily_earnings) do
      add :metrics, :map
      add :service, :text, null: false
      add :date, :date, null: false
      add :user_id, references(:users, on_delete: :nothing), null: false

      timestamps()
    end

    create unique_index(:daily_earnings, ["user_id", "date DESC", "service"])
  end
end
