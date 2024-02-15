defmodule DriversSeatCoop.Repo.Migrations.RemoveAvgHourlyEarningStats do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove(:average_gross_pay)
      remove(:average_net_pay)
    end
  end
end
