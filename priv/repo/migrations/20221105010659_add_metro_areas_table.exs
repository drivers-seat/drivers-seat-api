defmodule DriversSeatCoop.Repo.Migrations.AddMetroAreasTable do
  use Ecto.Migration

  def change do
    # id is supplied by the analytics database
    create table(:metro_areas, primary_key: false) do
      add(:id, :integer, primary_key: true)
      add(:name, :citext, null: false)
      timestamps()
    end

    create unique_index(:metro_areas, [:name])

    alter table(:users) do
      add(:metro_area_id, references(:metro_areas, on_delete: :nothing), null: true)
    end
  end
end
