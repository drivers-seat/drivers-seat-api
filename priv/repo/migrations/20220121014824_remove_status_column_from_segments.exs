defmodule DriversSeatCoop.Repo.Migrations.RemoveStatusColumnFromSegments do
  use Ecto.Migration

  def change do
    alter table(:segments) do
      remove(:status)
    end
  end
end
