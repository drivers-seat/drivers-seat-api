defmodule DriversSeatCoop.Repo.Migrations.PointsDateIndex do
  use Ecto.Migration
  @disable_ddl_transaction true
  @disable_migration_lock true

  def up do
    execute "create index concurrently points_recorded_at_date_user_id_working on points ((recorded_at::date), user_id) where status = 'working';"
  end

  def down do
    execute "drop index points_recorded_at_date_user_id_working;"
  end
end
