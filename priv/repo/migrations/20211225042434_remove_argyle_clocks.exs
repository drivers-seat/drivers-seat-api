defmodule DriversSeatCoop.Repo.Migrations.RemoveArgyleClocks do
  use Ecto.Migration

  def change do
    drop(table(:argyle_clock))
  end
end
