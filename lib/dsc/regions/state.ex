defmodule DriversSeatCoop.Regions.State do
  use Ecto.Schema
  import Ecto.Changeset

  @sync_fields ~w(id name abbrv geometry)a

  schema "region_state" do
    field :name, :string
    field :abbrv, :string
    field :geometry, Geo.PostGIS.Geometry
  end

  def sync_changeset(state, attrs) do
    state
    |> cast(attrs, @sync_fields)
    |> validate_required(@sync_fields)
    |> unique_constraint([:name])
    |> unique_constraint([:abbrv])
  end
end
