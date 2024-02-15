defmodule :"Elixir.DriversSeatCoop.Repo.Migrations.Change-is-beta-to-string" do
  use Ecto.Migration

  def change do
    alter table(:users) do
      modify :is_beta, :text
    end
  end
end
