defmodule DriversSeatCoopWeb.ExportValidator do
  alias Ecto.Changeset

  def user_performance_query(params) do
    types = %{
      date_start: :date,
      date_end: :date,
      include_non_p3_time: :boolean,
      groupings: {:array, :string}
    }

    data = %{}

    {data, types}
    |> Changeset.cast(params, Map.keys(types))
    |> Changeset.validate_required([:date_start, :date_end])
    |> Changeset.apply_action(:insert)
  end

  def expenses(params) do
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
