defmodule DriversSeatCoop.Repo.Migrations.AddOptOutPushNotificationsToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :opted_out_of_push_notifications, :boolean, default: false
    end
  end
end
