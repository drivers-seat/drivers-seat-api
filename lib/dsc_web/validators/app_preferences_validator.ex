defmodule DriversSeatCoopWeb.AppPreferencesValidator do
  alias Ecto.Changeset

  def update(params) do
    types = %{
      device_id: :string,
      app_version: :string,
      key: :string,
      value: :map
    }

    data = %{}

    changeset =
      {data, types}
      |> Changeset.cast(params, Map.keys(types))
      |> Changeset.validate_required([:device_id, :app_version, :key, :value])

    Changeset.apply_action(changeset, :insert)
  end
end
