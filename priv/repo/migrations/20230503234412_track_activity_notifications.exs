defmodule DriversSeatCoop.Repo.Migrations.TrackActivityNotifications do
  use Ecto.Migration

  def change do
    alter table(:activities) do
      add_if_not_exists(:notification_required, :boolean)
      add_if_not_exists(:notified_on, :utc_datetime)
    end

    create_if_not_exists(
      index(:activities, [:user_id, :deleted, :notification_required],
        name: :activities_user_id_deleted_notification_required
      )
    )

    create_if_not_exists(
      index(:activities, [:user_id, :notified_on], name: :activities_user_notified_on)
    )
  end
end
