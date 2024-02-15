defmodule DriversSeatCoop.Repo.Migrations.RemoveArgyleTermsAcceptedAt do
  use Ecto.Migration

  def change do
    alter table(:argyle_user) do
      remove(:argyle_terms_accepted_at)
    end
  end
end
