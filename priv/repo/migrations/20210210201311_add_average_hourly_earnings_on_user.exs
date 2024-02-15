defmodule DriversSeatCoop.Repo.Migrations.AddAverageHourlyEarningsOnUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :average_gross_pay, :float
      add :average_net_pay, :float
    end
  end
end
