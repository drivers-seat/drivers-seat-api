defmodule DriversSeatCoop.Repo.Migrations.FocusGroupUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :focus_group, :text
    end
  end
end
