defmodule DriversSeatCoop.Repo.Migrations.CreateIonicDeploy do
  use Ecto.Migration

  def change do
    create table(:build_type) do
      add :version_number, :string
      add :version_type, :string
      add :date_added, :naive_datetime
      add :notes, :string

      timestamps()
    end
  end
end
