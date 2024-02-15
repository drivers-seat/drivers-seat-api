defmodule DriversSeatCoop.Repo.Migrations.CreateTrips do
  use Ecto.Migration

  def change do
    create table(:trips) do
      add :passenger_count, :integer
      add :tnc_service_name, :text
      add :user_id, references(:users, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:trips, [:user_id])
  end
end
