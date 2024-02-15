defmodule DriversSeatCoop.Repo.Migrations.CreateResearchGroups do
  use Ecto.Migration

  def change do
    create table(:research_groups) do
      add :name, :text
      add :description, :text
      add :code, :text

      timestamps()
    end

    create unique_index(:research_groups, ["(lower(code))"],
             name: :research_groups_code_lower_index
           )
  end
end
