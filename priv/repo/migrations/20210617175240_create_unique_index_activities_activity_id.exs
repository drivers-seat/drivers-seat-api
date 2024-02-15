defmodule DriversSeatCoop.Repo.Migrations.CreateUniqueIndexActivitiesActivityId do
  use Ecto.Migration

  def change do
    create unique_index(:activities, ["activity_id"])
  end
end
