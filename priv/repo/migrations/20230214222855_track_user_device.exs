defmodule DriversSeatCoop.Repo.Migrations.TrackUserDevice do
  use Ecto.Migration

  def change do
    create table(:devices) do
      add(:device_id, :ciText, null: false)
      add(:user_id, references(:users, on_delete: :nothing), null: false)
      add(:device_name, :ciText)
      add(:app_version, :ciText)
      add(:device_platform, :ciText)
      add(:device_os, :ciText)
      add(:device_language, :ciText)

      timestamps()
    end

    create unique_index(:devices, [:user_id, :device_id], name: :devices_user_device_id_key)
  end
end
