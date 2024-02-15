defmodule DriversSeatCoop.Repo.Migrations.TrackUserServiceXref do
  use Ecto.Migration

  def change do
    create table(:user_service_identifiers) do
      add(:user_id, references(:users, on_delete: :nothing), null: false)
      add(:service, :citext, null: false)
      add(:identifiers, {:array, :text}, null: false)
      timestamps()
    end

    create unique_index(:user_service_identifiers, [:user_id, :service],
             name: :user_service_identifiers_ak
           )
  end
end
