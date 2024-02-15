defmodule DriversSeatCoop.EmployersTest do
  use DriversSeatCoop.DataCase
  alias DriversSeatCoop.Employers

  describe "employers" do
    test "matches on employer_name before additional keys" do
      employer_name_1 = "employer_#{Ecto.UUID.generate()}"
      employer_name_2 = "employer_#{Ecto.UUID.generate()}"
      employer_name_3 = "employer_#{Ecto.UUID.generate()}"

      employer =
        Employers.get_or_create_employer(employer_name_1, [employer_name_2, employer_name_3])

      assert employer != nil

      assert employer.name ==
               employer_name_1
               |> String.capitalize()
               |> String.replace("_", " ")
    end

    test "matches on additional keys before creating new employer" do
      employer_name_1 = "employer_#{Ecto.UUID.generate()}"
      employer_name_2 = "employer_#{Ecto.UUID.generate()}"
      employer_name_3 = "employer_#{Ecto.UUID.generate()}"

      expected = Employers.get_or_create_employer(employer_name_2)
      Employers.get_or_create_employer(employer_name_3)

      actual =
        Employers.get_or_create_employer(employer_name_1, [employer_name_2, employer_name_3])

      assert actual != nil
      assert actual == expected
    end

    test "trims, capitalizes, and removes dashes from name" do
      employer_name_1 = "employer_#{Ecto.UUID.generate()}"
      employer_name_2 = String.upcase("employer_#{Ecto.UUID.generate()}")
      employer_name_3 = String.upcase(" _  employer_#{Ecto.UUID.generate()}__")
      employer_name_4 = String.upcase("__#{employer_name_1}__")

      employer_1 = Employers.get_or_create_employer(employer_name_1)
      employer_2 = Employers.get_or_create_employer(employer_name_2)
      employer_3 = Employers.get_or_create_employer(employer_name_3)
      employer_4 = Employers.get_or_create_employer(employer_name_4)

      assert employer_1.name == format_name(employer_name_1)
      assert employer_2.name == format_name(employer_name_2)
      assert employer_3.name == format_name(employer_name_3)
      assert employer_1 == employer_4
    end

    test "doesn't create on nil or empty name" do
      assert nil == Employers.get_or_create_employer(nil)
      assert nil == Employers.get_or_create_employer(nil, nil)
      assert nil == Employers.get_or_create_employer(nil, ["", "_", " "])
    end
  end

  describe "service_classes" do
    test "trims, capitalizes, and removes dashes from name" do
      service_class_name_1 = "service_class_#{Ecto.UUID.generate()}"
      service_class_name_2 = String.upcase("service_class_#{Ecto.UUID.generate()}")
      service_class_name_3 = String.upcase(" _  service_class_#{Ecto.UUID.generate()}__")
      service_class_name_4 = String.upcase("__#{service_class_name_1}__")

      service_class_1 = Employers.get_or_create_service_class(service_class_name_1)
      service_class_2 = Employers.get_or_create_service_class(service_class_name_2)
      service_class_3 = Employers.get_or_create_service_class(service_class_name_3)
      service_class_4 = Employers.get_or_create_service_class(service_class_name_4)

      assert service_class_1.name == format_name(service_class_name_1)
      assert service_class_2.name == format_name(service_class_name_2)
      assert service_class_3.name == format_name(service_class_name_3)
      assert service_class_1 == service_class_4
    end

    test "doesn't create on nil or empty name" do
      assert nil == Employers.get_or_create_service_class(nil)
      assert nil == Employers.get_or_create_service_class(" ")
      assert nil == Employers.get_or_create_service_class(" __ ")
    end
  end

  describe "employer_service_classes" do
    test "creates diffent employer_service_class combos for employers with different service classes" do
      employer_1 = Employers.get_or_create_employer("employer_#{Ecto.UUID.generate()}")
      service_class_1 = Employers.get_or_create_service_class("sc_#{Ecto.UUID.generate()}")
      service_class_2 = Employers.get_or_create_service_class("sc_#{Ecto.UUID.generate()}")

      emp_svc_class_1 =
        Employers.get_or_create_employer_service_class(service_class_1.id, employer_1.id)

      emp_svc_class_2 =
        Employers.get_or_create_employer_service_class(service_class_2.id, employer_1.id)

      assert emp_svc_class_1 != nil
      assert emp_svc_class_1.employer_id == employer_1.id
      assert emp_svc_class_1.service_class_id == service_class_1.id

      assert emp_svc_class_2 != nil
      assert emp_svc_class_2.employer_id == employer_1.id
      assert emp_svc_class_2.service_class_id == service_class_2.id

      assert emp_svc_class_1 != assert(emp_svc_class_2)
    end

    test "does not create if either employer or service class are nil" do
      employer_1 = Employers.get_or_create_employer("employer_#{Ecto.UUID.generate()}")
      service_class_1 = Employers.get_or_create_service_class("sc_#{Ecto.UUID.generate()}")

      assert nil == Employers.get_or_create_employer_service_class(employer_1, nil)
      assert nil == Employers.get_or_create_employer_service_class(nil, nil)
      assert nil == Employers.get_or_create_employer_service_class(nil, service_class_1)
    end
  end

  defp format_name(employer_name) do
    employer_name
    |> String.replace("_", " ")
    |> String.trim()
    |> String.capitalize()
  end
end
