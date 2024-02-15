defmodule DriversSeatCoopWeb.EarningsValidator do
  alias Ecto.Changeset

  def detail(params) do
    types = %{
      work_date: :date
    }

    data = %{}

    {data, types}
    |> Changeset.cast(params, Map.keys(types))
    |> Changeset.validate_required([:work_date])
    |> Changeset.apply_action(:insert)
  end

  def summary_latest(params) do
    types = %{
      level: :string
    }

    data = %{}

    {data, types}
    |> Changeset.cast(params, Map.keys(types))
    |> Changeset.validate_required(Map.keys(types))
    |> Changeset.apply_action(:insert)
  end

  def index(params) do
    types = %{
      work_date_start: :date,
      work_date_end: :date,
      time_grouping: :string,
      date_start: :date,
      date_end: :date
    }

    data = %{}

    changeset =
      {data, types}
      |> Changeset.cast(params, Map.keys(types))

    # support backwards compatibility with old earnings endpoint
    changeset =
      if is_nil(Changeset.get_change(changeset, :work_date_start)) do
        date_start = Changeset.get_change(changeset, :date_start, ~D[1970-01-01])
        Changeset.put_change(changeset, :work_date_start, date_start)
      else
        changeset
      end

    # support backwards compatibility with old earnings endpoint
    changeset =
      if is_nil(Changeset.get_change(changeset, :work_date_end)) do
        date_end = Changeset.get_change(changeset, :date_end, Date.utc_today() |> Date.add(1))
        Changeset.put_change(changeset, :work_date_end, date_end)
      else
        changeset
      end

    changeset
    |> Changeset.validate_required([
      :work_date_start,
      :work_date_end
    ])
    |> Changeset.apply_action(:insert)
  end

  def activity(params) do
    types = %{
      activity_id: :integer
    }

    data = %{}

    {data, types}
    |> Changeset.cast(params, Map.keys(types))
    |> Changeset.validate_required([:activity_id])
    |> Changeset.apply_action(:insert)
  end

  def activity_index(params) do
    types = %{
      work_date_start: :date,
      work_date_end: :date
    }

    data = %{}

    {data, types}
    |> Changeset.cast(params, Map.keys(types))
    |> Changeset.validate_required([:work_date_start, :work_date_end])
    |> Changeset.apply_action(:insert)
  end

  def export(params) do
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
end
