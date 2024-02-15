defmodule Mix.Tasks.Dsc.BackfillArgyleActivities do
  use Mix.Task
  alias DriversSeatCoop.{Accounts, Repo}
  alias DriversSeatCoop.Argyle.Oban.BackfillArgyleActivities

  def run(_args) do
    Mix.Task.run("app.start")

    try do
      reducer = fn {changesets, index}, multi ->
        Oban.insert_all(multi, "batch_#{index}", changesets)
      end

      Accounts.list_users_with_argyle_linked()
      |> Enum.shuffle()
      |> Enum.map(fn user ->
        %{user_id: user.id}
        |> BackfillArgyleActivities.new()
      end)
      |> Enum.chunk_every(500)
      |> Enum.with_index()
      |> Enum.reduce(Ecto.Multi.new(), reducer)
      |> Repo.transaction()
    rescue
      e ->
        Sentry.capture_exception(e)
        reraise e, __STACKTRACE__
    end
  end
end
