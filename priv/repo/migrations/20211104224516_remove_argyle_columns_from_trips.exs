defmodule DriversSeatCoop.Repo.Migrations.RemoveArgyleColumnsFromTrips do
  use Ecto.Migration

  def change do
    alter table(:trips) do
      remove(:accepted_time)
      remove(:activity_id)
      remove(:is_argyle)
    end
  end
end
