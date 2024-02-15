defmodule DriversSeatCoop.Repo.Migrations.AddDateToActivities do
  use Ecto.Migration

  def change do
    alter table(:activities) do
      add :date, :date
    end
  end
end
