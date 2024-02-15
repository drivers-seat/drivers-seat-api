defmodule DriversSeatCoop.Repo.Migrations.AddDateIndexToActivities do
  use Ecto.Migration

  @disable_migration_lock true
  @disable_ddl_transaction true

  def change do
    create(index(:activities, :date, concurrently: true))
  end
end
