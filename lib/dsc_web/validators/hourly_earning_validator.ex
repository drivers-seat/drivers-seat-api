defmodule DriversSeatCoopWeb.HourlyEarningValidator do
  alias Ecto.Changeset

  def index(params) do
    types = %{
      max_date: :date,
      since_date: :date
    }

    data = %{}

    changeset =
      {data, types}
      |> Changeset.cast(params, Map.keys(types))

    Changeset.apply_action(changeset, :insert)
  end
end
