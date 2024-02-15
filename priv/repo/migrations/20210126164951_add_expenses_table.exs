defmodule DriversSeatCoop.Repo.Migrations.AddExpensesTable do
  use Ecto.Migration

  def change do
    create table(:expenses) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :category, :text, null: false
      add :name, :text, null: false
      add :date, :date, null: false
      add :money, :float, null: false

      timestamps()
    end
  end
end
