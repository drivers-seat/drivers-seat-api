defmodule DriversSeatCoop.Repo.Migrations.AddJobToDailyEarning do
  use Ecto.Migration

  def change do
    alter table(:daily_earnings) do
      add :job, :jsonb
    end
  end
end
