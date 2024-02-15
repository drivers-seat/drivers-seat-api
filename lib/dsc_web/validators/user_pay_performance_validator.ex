defmodule DriversSeatCoopWeb.UserPayPerformanceValidator do
  alias Ecto.Changeset

  def show(params) do
    types = %{
      user_id: :integer,
      date_start: :date,
      date_end: :date
    }

    data = %{}

    changeset =
      {data, types}
      |> Changeset.cast(params, Map.keys(types))
      |> Changeset.validate_required([:user_id])

    Changeset.apply_action(changeset, :insert)
  end
end
