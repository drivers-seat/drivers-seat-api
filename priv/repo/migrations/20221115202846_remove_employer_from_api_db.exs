defmodule DriversSeatCoop.Repo.Migrations.RemoveEmployerFromApiDb do
  use Ecto.Migration

  def change do
    drop_if_exists table(:employers)

    execute("DROP TYPE IF EXISTS service_class")
  end
end
