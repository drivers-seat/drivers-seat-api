defmodule DriversSeatCoop.Repo.Migrations.DropSegmentsTable do
  use Ecto.Migration

  def change do
    drop_if_exists table(:segments)
  end
end
