defmodule DriversSeatCoop.Employers.Employer do
  use Ecto.Schema
  import Ecto.Changeset

  @required_fields ~w(name)a

  schema "employers" do
    field :name, :string
    timestamps()
  end

  def changeset(employer, attrs) do
    employer
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint([:name], name: :employers_name_index)
  end
end
