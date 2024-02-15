defmodule DriversSeatCoop.Repo.Migrations.RemoveArgyleActivityIdFromPoints do
  use Ecto.Migration

  def change do
    alter table(:points) do
      remove(:argyle_activity_id)
    end
  end
end
