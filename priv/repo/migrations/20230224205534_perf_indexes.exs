defmodule DriversSeatCoop.Repo.Migrations.PerfIndexes do
  use Ecto.Migration

  def change do
    create_if_not_exists(
      index(:shifts, [:user_id, :deleted, :start_time, :end_time],
        name: :shifts_user_deleted_start_end_index
      )
    )
  end
end
