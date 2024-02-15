defmodule DriversSeatCoop.Regions.County do
  use Ecto.Schema
  import Ecto.Changeset

  @sync_fields ~w(id name region_id_state geometry)a

  schema "region_county" do
    field :name, :string
    field :geometry, Geo.PostGIS.Geometry
    belongs_to :state, DriversSeatCoop.Regions.State, foreign_key: :region_id_state
  end

  def sync_changeset(county, attrs) do
    county
    |> cast(attrs, @sync_fields)
    |> validate_required(@sync_fields)
    |> unique_constraint([:region_id_state, :name])
    |> assoc_constraint(:state)
  end
end
