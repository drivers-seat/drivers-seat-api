defmodule DriversSeatCoop.Repo.Migrations.TrackUserPopulations do
  use Ecto.Migration

  def change do
    create table(:population_members) do
      add(:user_id, references(:users, on_delete: :nothing), null: false)
      add(:population_type, :citext, null: false)
      add(:population, :citext, null: false)
      add(:additional_data, :map)
      timestamps()
    end

    create unique_index(:population_members, [:user_id, :population_type, :population],
             name: :population_members_key
           )
  end
end
