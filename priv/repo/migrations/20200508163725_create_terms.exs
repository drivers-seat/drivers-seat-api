defmodule DriversSeatCoop.Repo.Migrations.CreateTerms do
  use Ecto.Migration

  def change do
    create table(:terms) do
      add :title, :text
      add :text, :text
      add :required_at, :naive_datetime
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:terms, [:user_id])
  end
end
