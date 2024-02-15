defmodule DriversSeatCoop.Repo.Migrations.CreateArgyleTokenColumnInUsers do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add(:argyle_accounts, :jsonb)
      add(:argyle_token, :text)
      add(:argyle_user_id, :text)
    end

    execute("""
    UPDATE users
    SET argyle_accounts = argyle_user.accounts
    FROM argyle_user
    WHERE argyle_user.user_id = users.id
    """)

    execute("""
    UPDATE users
    SET argyle_token = argyle_user.user_token
    FROM argyle_user
    WHERE argyle_user.user_id = users.id
    """)

    execute("""
    UPDATE users
    SET argyle_user_id = argyle_user.argyle_id
    FROM argyle_user
    WHERE argyle_user.user_id = users.id
    """)
  end

  def down do
    alter table(:users) do
      remove(:argyle_accounts)
      remove(:argyle_token)
      remove(:argyle_user_id)
    end
  end
end
