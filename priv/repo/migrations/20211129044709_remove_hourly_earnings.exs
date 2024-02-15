defmodule DriversSeatCoop.Repo.Migrations.RemoveHourlyEarnings do
  use Ecto.Migration

  def change do
    drop(table(:hourly_earnings))
  end
end
