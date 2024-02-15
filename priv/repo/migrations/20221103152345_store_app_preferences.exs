defmodule DriversSeatCoop.Repo.Migrations.StoreAppPreferences do
  use Ecto.Migration

  def change do
    create table(:user_app_preferences) do
      add(:user_id, references(:users, on_delete: :nothing), null: false)
      add(:key, :ciText, null: false)
      add(:value, :jsonb, null: false)
      add(:last_updated_device_id, :text, null: false)
      add(:last_updated_app_version, :text, null: false)
      timestamps()
    end

    create unique_index(:user_app_preferences, [:user_id, :key],
             name: :user_app_preferences_user_key
           )
  end
end
