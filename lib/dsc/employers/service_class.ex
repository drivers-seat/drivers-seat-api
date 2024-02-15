defmodule DriversSeatCoop.Employers.ServiceClass do
  use Ecto.Schema
  import Ecto.Changeset

  @required_fields ~w(name)a

  schema "service_classes" do
    field :name, :string
    timestamps()
  end

  def changeset(service_class, attrs) do
    service_class
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint([:name], name: :service_classes_name_index)
  end
end
