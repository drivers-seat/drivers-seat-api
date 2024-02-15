defmodule DriversSeatCoop.Repo.Migrations.AddLinkedAccountsTable do
  use Ecto.Migration

  def change do
    create table(:user_gig_accounts) do
      add(:user_id, references(:users, on_delete: :nothing), null: false)
      add(:argyle_id, :citext, null: false)
      add(:employer, :citext)

      add(:is_connected, :boolean, null: false, default: false)
      add(:connection_has_errors, :boolean, null: false, default: false)
      add(:connection_status, :citext)
      add(:connection_error_code, :citext)
      add(:connection_error_message, :citext)
      add(:connection_updated_at, :utc_datetime)

      add(:is_synced, :boolean, null: false, default: false)
      add(:activity_status, :citext)
      add(:activity_count, :integer)
      add(:activities_updated_at, :utc_datetime)
      add(:activity_date_min, :utc_datetime)
      add(:activity_date_max, :utc_datetime)

      add(:deleted, :boolean, null: false, default: false)

      add(:account_data, :map)

      timestamps()
    end

    create unique_index(:user_gig_accounts, [:argyle_id], name: :user_gig_accounts_argyle_id)
  end
end
