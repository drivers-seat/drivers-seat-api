defmodule DriversSeatCoop.Repo.Migrations.RemoveBuildTypes do
  use Ecto.Migration

  def change do
    drop(table(:build_type))
  end
end
