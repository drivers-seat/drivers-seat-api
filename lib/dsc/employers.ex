defmodule DriversSeatCoop.Employers do
  @moduledoc """
  Provides functions for obtaining information about employers
  and the services that they offer
  """

  alias DriversSeatCoop.Employers.Employer
  alias DriversSeatCoop.Employers.EmployerServiceClass
  alias DriversSeatCoop.Employers.ServiceClass
  alias DriversSeatCoop.Repo

  import Ecto.Query

  def get_employer_by_id(id) do
    from(e in Employer)
    |> where([e], e.id == ^id)
    |> limit(1)
    |> Repo.one()
  end

  def get_service_class_by_id(id) do
    from(sc in ServiceClass)
    |> where([sc], sc.id == ^id)
    |> limit(1)
    |> Repo.one()
  end

  def get_employer_by_name(name_or_names) do
    names =
      List.wrap(name_or_names)
      |> Enum.map(fn n ->
        n
        |> String.replace("_", "")
        |> String.replace("-", "")
        |> String.replace(" ", "")
        |> String.replace(".", "")
        |> String.replace(",", "")
        |> String.downcase()
      end)

    from(employer in Employer)
    |> where(
      [e],
      fragment(
        "LOWER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(?, ' ', ''),'_',''),'.',''),',',''),'-',''))",
        e.name
      ) in ^names
    )
    |> limit(1)
    |> Repo.one()
  end

  def get_or_create_employer(employer_name), do: get_or_create_employer(employer_name, nil)
  def get_or_create_employer(nil = _employer_name, _match_key_or_keys), do: nil

  def get_or_create_employer(employer_name, match_key_or_keys) do
    employer = get_employer_by_name([employer_name] ++ List.wrap(match_key_or_keys))

    if is_nil(employer) do
      employer_name =
        employer_name
        |> String.replace("_", " ")
        |> String.trim()
        |> String.capitalize()

      {:ok, employer} =
        Employer.changeset(
          %Employer{},
          %{
            name: employer_name
          }
        )
        |> Repo.insert(
          on_conflict: :nothing,
          conflict_target: :name,
          returning: true
        )

      employer
    else
      employer
    end
  end

  def get_or_create_service_class(nil = _service_class_name), do: nil

  def get_or_create_service_class(service_class_name) do
    service_class_name =
      "#{service_class_name}"
      |> String.replace("_", " ")
      |> String.trim()
      |> String.capitalize()

    service_class =
      from(sc in ServiceClass)
      |> where([sc], sc.name == ^service_class_name)
      |> limit(1)
      |> Repo.one()

    if is_nil(service_class) and service_class_name != "" do
      service_class_name =
        service_class_name
        |> String.trim()
        |> String.capitalize()

      {:ok, service_class} =
        ServiceClass.changeset(
          %ServiceClass{},
          %{
            name: service_class_name
          }
        )
        |> Repo.insert(
          on_conflict: :nothing,
          conflict_target: :name,
          returning: true
        )

      service_class
    else
      service_class
    end
  end

  def get_or_create_employer_service_class(nil = _service_class_id, _employer_id), do: nil
  def get_or_create_employer_service_class(_service_class_id, nil = _employer_id), do: nil

  def get_or_create_employer_service_class(service_class_id, employer_id) do
    employer_service_class =
      from(esc in EmployerServiceClass)
      |> where([esc], esc.employer_id == ^employer_id)
      |> where([esc], esc.service_class_id == ^service_class_id)
      |> limit(1)
      |> Repo.one()

    if is_nil(employer_service_class) do
      employer = get_employer_by_id(employer_id)
      service_class = get_service_class_by_id(service_class_id)

      name = "#{employer.name} #{service_class.name}"

      {:ok, employer_service_class} =
        EmployerServiceClass.changeset(
          %EmployerServiceClass{},
          %{
            employer_id: employer_id,
            service_class_id: service_class_id,
            name: name
          }
        )
        |> Repo.insert(
          on_conflict: :nothing,
          conflict_target: [:service_class_id, :employer_id],
          returning: true
        )

      employer_service_class
    else
      employer_service_class
    end
  end

  def list_employers do
    from(emp in Employer)
    |> Repo.all()
  end

  def list_service_classes do
    from(service_class in ServiceClass)
    |> Repo.all()
  end

  def list_employer_service_classes(preload_employer \\ true) do
    qry = from(esc in EmployerServiceClass)

    qry =
      if preload_employer,
        do:
          qry
          |> preload(:employer)
          |> preload(:service_class),
        else: qry

    Repo.all(qry)
  end
end
