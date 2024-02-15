defmodule DriversSeatCoop.Repo.Migrations.ChangeDailyEarningJobToJobs do
  use Ecto.Migration

  def change do
    alter table(:daily_earnings) do
      remove :job
      add :jobs, {:array, :jsonb}
    end

    drop unique_index(:daily_earnings, ["user_id", "date DESC", "service"])
  end
end
