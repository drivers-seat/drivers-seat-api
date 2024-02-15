defmodule DriversSeatCoopWeb.GoalsValidator do
  alias Ecto.Changeset

  alias DriversSeatCoop.Goals.GoalFrequency
  alias DriversSeatCoop.Goals.GoalType

  def index(params) do
    types = %{
      frequency: GoalFrequency
    }

    changeset =
      {%{}, types}
      |> Changeset.cast(params, Map.keys(types))
      |> Changeset.validate_required([:frequency])

    Changeset.apply_action(changeset, :insert)
  end

  def save(params) do
    types = %{
      type: GoalType,
      frequency: GoalFrequency,
      start_date: :date,
      sub_goals: :map,
      replace: :date
    }

    changeset =
      {%{}, types}
      |> Changeset.cast(params, Map.keys(types))
      |> Changeset.validate_required([:type, :frequency, :start_date, :sub_goals])

    Changeset.apply_action(changeset, :insert)
  end

  def delete(params) do
    types = %{
      type: GoalType,
      frequency: GoalFrequency,
      start_date: :date
    }

    changeset =
      {%{}, types}
      |> Changeset.cast(params, Map.keys(types))
      |> Changeset.validate_required(Map.keys(types))

    Changeset.apply_action(changeset, :insert)
  end

  def performance(params) do
    types = %{
      frequency: GoalFrequency,
      window_date: :date
    }

    changeset =
      {%{}, types}
      |> Changeset.cast(params, Map.keys(types))
      |> Changeset.validate_required([:frequency, :window_date])

    Changeset.apply_action(changeset, :insert)
  end
end
