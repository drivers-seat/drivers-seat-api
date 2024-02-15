defmodule DriversSeatCoop.Repo.Migrations.AddSourceToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :source, :text
    end
  end
end
