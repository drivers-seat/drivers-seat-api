defmodule DriversSeatCoop.Repo.Migrations.ConvertEmailToCitext do
  use Ecto.Migration

  def change do
    execute("""
    delete from accepted_terms
    where id in (
      select accepted_terms.id
      from accepted_terms
      join users ON users.id = accepted_terms.user_id
      where email is null
    )
    """)

    execute("""
    delete from trips
    where id in (
      select trips.id
      from trips
      join users on users.id = trips.user_id
      where email is null
    )
    """)

    execute("delete from users where email is null")

    alter table(:users) do
      # make email case-insensitive and not null
      modify(:email, :citext, null: false)
    end

    # get rid of old index that used lower() and replace it with a normal one
    drop(index(:users, :email_lower))
    create(unique_index(:users, [:email]))
  end
end
