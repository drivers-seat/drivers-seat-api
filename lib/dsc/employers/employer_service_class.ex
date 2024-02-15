defmodule DriversSeatCoop.Employers.EmployerServiceClass do
  use Ecto.Schema
  import Ecto.Changeset
  alias DriversSeatCoop.Employers.Employer
  alias DriversSeatCoop.Employers.ServiceClass

  @required_fields ~w(employer_id service_class_id name)a
  @optional_fields ~w(reports_mileage)a

  schema "employer_service_classes" do
    belongs_to(:employer, Employer)
    belongs_to(:service_class, ServiceClass)
    field :name, :string
    field :reports_mileage, :boolean, default: false
    timestamps()
  end

  def changeset(employer_service_class, attrs) do
    employer_service_class
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> assoc_constraint(:employer)
    |> assoc_constraint(:service_class)
    |> unique_constraint([:service_class_id, :employer_id],
      name: :employer_service_classes_service_class_id_employer_id_index
    )
  end
end
