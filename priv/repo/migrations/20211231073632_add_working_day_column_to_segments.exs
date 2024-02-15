defmodule DriversSeatCoop.Repo.Migrations.AddWorkingDayColumnToSegments do
  use Ecto.Migration

  def change do
    alter table(:segments) do
      add(:working_day, :date)
    end
  end
end
