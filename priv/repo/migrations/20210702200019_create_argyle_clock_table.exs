defmodule DriversSeatCoop.Repo.Migrations.CreateArgyleClockTable do
  use Ecto.Migration

  def change do
    create table(:argyle_clock) do
      add :user_id, references(:users, on_delete: :nothing), null: false

      add :time, :naive_datetime
      add :mode, :string

      timestamps()
    end
  end
end
