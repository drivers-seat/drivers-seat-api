defmodule DriversSeatCoop.Repo.Migrations.CreateAcceptedTerms do
  use Ecto.Migration

  def change do
    create table(:accepted_terms) do
      add :accepted_at, :naive_datetime
      add :terms_id, references(:terms, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create unique_index(:accepted_terms, [:user_id, :terms_id])
  end
end
