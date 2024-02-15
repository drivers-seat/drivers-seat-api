defmodule DriversSeatCoopWeb.ArgyleUserValidator do
  import Ecto.Changeset

  def create(params), do: update(Map.get(params, "argyle_user"))

  def update(params) do
    types = %{
      argyle_id: :string
    }

    data = %{}

    {data, types}
    |> cast(params, Map.keys(types))
    |> apply_action(:insert)
  end
end
