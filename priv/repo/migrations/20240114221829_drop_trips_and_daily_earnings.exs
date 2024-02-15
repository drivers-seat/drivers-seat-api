defmodule DriversSeatCoop.Repo.Migrations.DropTripsAndDailyEarnings do
  use Ecto.Migration

  def change do
    drop_if_exists table(:trips)
    drop_if_exists table(:daily_earnings)
    drop_if_exists table(:tmpdeletealloc)
  end
end
