defmodule DriversSeatCoop.Repo.Migrations.AddActivityData do
  use Ecto.Migration

  def change do
    alter table(:activities) do
      add :activity_data, :jsonb
    end
  end
end
