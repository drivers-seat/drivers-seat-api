defmodule DriversSeatCoop.Repo.Migrations.AddUniqueIndexsForExpensesAndHourlyEarnings do
  use Ecto.Migration

  def change do
    create unique_index(:hourly_earnings, ["user_id", "date DESC"])
  end
end
