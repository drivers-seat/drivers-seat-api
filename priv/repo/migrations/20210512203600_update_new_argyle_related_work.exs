defmodule DriversSeatCoop.Repo.Migrations.UpdateNewArgyleRelatedWork do
  use Ecto.Migration

  def change do
    alter table(:argyle_user) do
      add :argyle_terms_accepted_at, :naive_datetime
    end
  end
end
