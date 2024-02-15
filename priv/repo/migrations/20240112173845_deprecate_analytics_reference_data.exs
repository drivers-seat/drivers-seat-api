defmodule DriversSeatCoop.Repo.Migrations.DeprecateAnalyticsReferenceData do
  use Ecto.Migration

  def change do
    create table(:service_classes) do
      add(:name, :citext, null: false)
      timestamps()
    end

    create unique_index(:service_classes, [:name], name: :service_classes_name_index)

    execute "INSERT INTO service_classes(id, name, inserted_at, updated_at) VALUES (1,'Rideshare', now() at time zone 'utc', now() at time zone 'utc')"

    execute "INSERT INTO service_classes(id, name, inserted_at, updated_at) VALUES (2,'Delivery', now() at time zone 'utc', now() at time zone 'utc')"

    execute "INSERT INTO service_classes(id, name, inserted_at, updated_at) VALUES (3,'Services', now() at time zone 'utc', now() at time zone 'utc')"

    execute "ALTER SEQUENCE service_classes_id_seq RESTART WITH 4"

    create table(:employers) do
      add(:name, :citext, null: false)
      timestamps()
    end

    create unique_index(:employers, [:name], name: :employers_name_index)

    execute "INSERT INTO employers(id, name, inserted_at, updated_at) VALUES(100, 'Amazon Flex', now() at time zone 'utc', now() at time zone 'utc')"

    execute "INSERT INTO employers(id, name, inserted_at, updated_at) VALUES(101, 'Doordash', now() at time zone 'utc', now() at time zone 'utc')"

    execute "INSERT INTO employers(id, name, inserted_at, updated_at) VALUES(102, 'Gopuff', now() at time zone 'utc', now() at time zone 'utc')"

    execute "INSERT INTO employers(id, name, inserted_at, updated_at) VALUES(103, 'Grubhub', now() at time zone 'utc', now() at time zone 'utc')"

    execute "INSERT INTO employers(id, name, inserted_at, updated_at) VALUES(104, 'Instacart', now() at time zone 'utc', now() at time zone 'utc')"

    execute "INSERT INTO employers(id, name, inserted_at, updated_at) VALUES(105, 'Lyft', now() at time zone 'utc', now() at time zone 'utc')"

    execute "INSERT INTO employers(id, name, inserted_at, updated_at) VALUES(106, 'Spark Driver', now() at time zone 'utc', now() at time zone 'utc')"

    execute "INSERT INTO employers(id, name, inserted_at, updated_at) VALUES(107, 'Uber', now() at time zone 'utc', now() at time zone 'utc')"

    execute "INSERT INTO employers(id, name, inserted_at, updated_at) VALUES(108, 'Roadie', now() at time zone 'utc', now() at time zone 'utc')"

    execute "INSERT INTO employers(id, name, inserted_at, updated_at) VALUES(109, 'Favor', now() at time zone 'utc', now() at time zone 'utc')"

    execute "INSERT INTO employers(id, name, inserted_at, updated_at) VALUES(110, 'Dolly', now() at time zone 'utc', now() at time zone 'utc')"

    execute "INSERT INTO employers(id, name, inserted_at, updated_at) VALUES(111, 'Shipt', now() at time zone 'utc', now() at time zone 'utc')"

    execute "ALTER SEQUENCE employers_id_seq RESTART WITH 112"

    create table(:employer_service_classes) do
      add(:employer_id, references(:employers, on_delete: :nothing), null: false)
      add(:service_class_id, references(:service_classes, on_delete: :nothing), null: false)
      add(:name, :citext, null: false)
      add(:reports_mileage, :boolean, null: false, default: false)
      timestamps()
    end

    create unique_index(:employer_service_classes, [:service_class_id, :employer_id],
             name: :employer_service_classes_service_class_id_employer_id_index
           )

    execute "INSERT INTO employer_service_classes(id, employer_id, service_class_id, reports_mileage, name, inserted_at, updated_at) VALUES(1, 100, 2,  false, 'Amazon Flex', now() at time zone 'utc', now() at time zone 'utc')"

    execute "INSERT INTO employer_service_classes(id, employer_id, service_class_id, reports_mileage, name, inserted_at, updated_at) VALUES(2, 101, 2,  false, 'Doordash', now() at time zone 'utc', now() at time zone 'utc')"

    execute "INSERT INTO employer_service_classes(id, employer_id, service_class_id, reports_mileage, name, inserted_at, updated_at) VALUES(3, 102, 2,  false, 'Gopuff', now() at time zone 'utc', now() at time zone 'utc')"

    execute "INSERT INTO employer_service_classes(id, employer_id, service_class_id, reports_mileage, name, inserted_at, updated_at) VALUES(4, 103, 2,  true,  'Grubhub', now() at time zone 'utc', now() at time zone 'utc')"

    execute "INSERT INTO employer_service_classes(id, employer_id, service_class_id, reports_mileage, name, inserted_at, updated_at) VALUES(5, 104, 2,  true,  'Instacart', now() at time zone 'utc', now() at time zone 'utc')"

    execute "INSERT INTO employer_service_classes(id, employer_id, service_class_id, reports_mileage, name, inserted_at, updated_at) VALUES(6, 105, 1,  true,  'Lyft Rideshare', now() at time zone 'utc', now() at time zone 'utc')"

    execute "INSERT INTO employer_service_classes(id, employer_id, service_class_id, reports_mileage, name, inserted_at, updated_at) VALUES(7, 106, 2,  true,  'Spark Driver', now() at time zone 'utc', now() at time zone 'utc')"

    execute "INSERT INTO employer_service_classes(id, employer_id, service_class_id, reports_mileage, name, inserted_at, updated_at) VALUES(8, 107, 1,  true,  'Uber Rideshare', now() at time zone 'utc', now() at time zone 'utc')"

    execute "INSERT INTO employer_service_classes(id, employer_id, service_class_id, reports_mileage, name, inserted_at, updated_at) VALUES(9, 107, 2,  true,  'Uber Delivery', now() at time zone 'utc', now() at time zone 'utc')"

    execute "INSERT INTO employer_service_classes(id, employer_id, service_class_id, reports_mileage, name, inserted_at, updated_at) VALUES(10, 105, 2, true,  'Lyft Delivery', now() at time zone 'utc', now() at time zone 'utc')"

    execute "INSERT INTO employer_service_classes(id, employer_id, service_class_id, reports_mileage, name, inserted_at, updated_at) VALUES(11, 108, 2, true,  'Roadie', now() at time zone 'utc', now() at time zone 'utc')"

    execute "INSERT INTO employer_service_classes(id, employer_id, service_class_id, reports_mileage, name, inserted_at, updated_at) VALUES(12, 109, 2, true,  'Favor', now() at time zone 'utc', now() at time zone 'utc')"

    execute "INSERT INTO employer_service_classes(id, employer_id, service_class_id, reports_mileage, name, inserted_at, updated_at) VALUES(13, 110, 3, true,  'Dolly', now() at time zone 'utc', now() at time zone 'utc')"

    execute "INSERT INTO employer_service_classes(id, employer_id, service_class_id, reports_mileage, name, inserted_at, updated_at) VALUES(14, 111, 2, false, 'Shipt', now() at time zone 'utc', now() at time zone 'utc')"

    execute "ALTER SEQUENCE employer_service_classes_id_seq RESTART WITH 15"
  end
end
