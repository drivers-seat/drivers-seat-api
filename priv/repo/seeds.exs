alias DriversSeatCoop.Repo
alias DriversSeatCoop.Accounts.User
alias DriversSeatCoop.Legal

# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     DriversSeatCoop.Repo.insert!(%DriversSeatCoop.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

user_attrs = %{
  email: "admin@driversseat.co",
  first_name: "admin",
  last_name: "user",
  password: "password!",
  role: "admin"
}

{:ok, user} =
  %User{}
  |> User.changeset(user_attrs)
  |> Repo.insert(
    on_conflict: {:replace_all_except, [:id, :inserted_at]},
    conflict_target: :email
  )

{:ok, user} =
  user
  |> User.admin_changeset(user_attrs)
  |> Repo.update()

term = Legal.get_current_term()

if is_nil(term) do
  Legal.create_terms(
    %{
      text: "Initial Terms of Service",
      title: "Development Environment",
      required_at: DateTime.new!(~D[2019-01-01], ~T[00:00:00])
    },
    user.id
  )
end
