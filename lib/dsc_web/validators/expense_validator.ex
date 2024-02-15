defmodule DriversSeatCoopWeb.ExpenseValidator do
  alias Ecto.Changeset

  def index(params) do
    types = %{
      limit: :integer,
      max_date: :date,
      since_date: :date
    }

    data = %{}

    changeset =
      {data, types}
      |> Changeset.cast(params, Map.keys(types))
      |> Changeset.validate_number(:limit, greater_than: 0, less_than_or_equal_to: 200)

    Changeset.apply_action(changeset, :insert)
  end

  def export(params) do
    types = %{
      date_start: :date,
      date_end: :date
    }

    data = %{}

    {data, types}
    |> Changeset.cast(params, Map.keys(types))
    |> Changeset.validate_required([:date_start, :date_end])
    |> Changeset.apply_action(:insert)
  end
end
