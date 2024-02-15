defmodule DriversSeatCoop.ScheduledShifts do
  import Ecto.Query, warn: false
  alias DriversSeatCoop.Repo
  alias DriversSeatCoop.ScheduledShifts.ScheduledShift

  @doc """
  Return a list of scheduled shifts for a user
  """
  def list_scheduled_shifts_by_user_id(user_id) do
    from(s in ScheduledShift,
      where: s.user_id == ^user_id
    )
    |> Repo.all()
  end

  @doc """
  Replaces a user's entire work schedule/scheduled shifts
  """
  def update_scheduled_shifts(attrs_list, user_id) when is_list(attrs_list) do
    qry_delete = from(s in ScheduledShift, where: s.user_id == ^user_id)

    # delete existing information for the user
    multi =
      Ecto.Multi.new()
      |> Ecto.Multi.delete_all(:delete_items, qry_delete)

    # add new items to multi
    multi =
      Enum.with_index(attrs_list)
      |> Enum.reduce(multi, fn {attrs, index}, multi ->
        changeset =
          %ScheduledShift{user_id: user_id}
          |> ScheduledShift.changeset(attrs)

        Ecto.Multi.insert(multi, index, changeset)
      end)

    Repo.transaction(multi)
    |> case do
      {:ok, _} -> {:ok, list_scheduled_shifts_by_user_id(user_id)}
      {:error, _failed_operation, failed_changeset, _changes_so_far} -> {:error, failed_changeset}
    end
  end
end
