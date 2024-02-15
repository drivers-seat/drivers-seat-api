defmodule DriversSeatCoopWeb.ShiftValidator do
  alias Ecto.Changeset

  def index(params) do
    types = %{
      limit: :integer,
      max_id: :integer,
      date: :date,
      max_date: :date,
      since_date: :date,
      work_date: :date,
      include_mileage: :boolean
    }

    data = %{}

    changeset =
      {data, types}
      |> Changeset.cast(params, Map.keys(types))
      |> Changeset.validate_number(:limit, greater_than: 0, less_than_or_equal_to: 200)

    Changeset.apply_action(changeset, :insert)
  end

  def update_working_times(params) do
    new_shifts = Map.get(params, "new_shifts")

    params =
      if is_nil(new_shifts) do
        params
      else
        new_shifts =
          new_shifts
          |> Enum.map(fn new_shift ->
            start_time_8601 = Map.get(new_shift, "start_time")
            {:ok, dtm, _} = DateTime.from_iso8601(start_time_8601)

            new_shift = Map.put(new_shift, "start_time", dtm)

            end_time_8601 = Map.get(new_shift, "end_time")
            {:ok, dtm, _} = DateTime.from_iso8601(end_time_8601)

            Map.put(new_shift, "end_time", dtm)
          end)

        params
        |> Map.put("new_shifts", new_shifts)
      end

    types = %{
      work_date: :date,
      new_shifts: {:array, :map}
    }

    data = %{}

    {data, types}
    |> Changeset.cast(params, Map.keys(types))
    |> Changeset.validate_required([:work_date, :new_shifts])
    |> Changeset.apply_action(:insert)
  end
end
