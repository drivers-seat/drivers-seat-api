defmodule DriversSeatCoop.Repo.Migrations.AddUserIdIndexToActivities do
  use Ecto.Migration

  @disable_migration_lock true
  @disable_ddl_transaction true

  def change do
    create(index(:activities, :user_id, concurrently: true))
  end
end
