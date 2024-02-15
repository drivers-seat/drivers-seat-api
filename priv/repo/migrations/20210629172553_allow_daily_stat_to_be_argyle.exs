defmodule DriversSeatCoop.Repo.Migrations.AllowDailyStatToBeArgyle do
  use Ecto.Migration

  def change do
    alter table(:daily_stats) do
      add :is_argyle, :boolean, default: false
    end

    drop unique_index(:daily_stats, ["user_id", "date DESC"])

    create unique_index(:daily_stats, ["user_id", "date DESC", "is_argyle"])
  end
end
