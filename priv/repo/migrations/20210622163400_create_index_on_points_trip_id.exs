defmodule DriversSeatCoop.Repo.Migrations.CreateIndexOnPointsTripId do
  use Ecto.Migration
  @disable_migration_lock true
  @disable_ddl_transaction true

  def change do
    create index(:points, :trip_id, concurrently: true)
  end
end
