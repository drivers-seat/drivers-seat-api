defmodule DriversSeatCoop.Repo.Migrations.RemoveDailyStats do
  use Ecto.Migration

  def change do
    drop(table(:daily_stats))
  end
end
