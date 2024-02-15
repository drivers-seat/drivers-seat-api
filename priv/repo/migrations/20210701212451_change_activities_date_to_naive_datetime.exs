defmodule DriversSeatCoop.Repo.Migrations.ChangeActivitiesDateToNaiveDatetime do
  use Ecto.Migration

  def change do
    alter table(:activities) do
      modify :date, :naive_datetime
    end
  end
end
