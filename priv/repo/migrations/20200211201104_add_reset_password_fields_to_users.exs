defmodule DriversSeatCoop.Repo.Migrations.AddResetPasswordFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :reset_password_token, :string
      add :reset_password_token_expires_at, :naive_datetime_usec
    end
  end
end
