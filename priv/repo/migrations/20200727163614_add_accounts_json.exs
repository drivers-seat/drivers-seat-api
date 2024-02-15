defmodule DriversSeatCoop.Repo.Migrations.AddAccountsJson do
  use Ecto.Migration

  def change do
    alter table(:argyle_account) do
      add :accounts, :jsonb
      remove :userToken
      add :user_token, :string
    end
  end
end
