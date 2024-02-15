defmodule DriversSeatCoop.Repo.Migrations.RemoveArgyleUserTable do
  use Ecto.Migration

  def change do
    drop(table(:argyle_user))
  end
end
