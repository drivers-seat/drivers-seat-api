defmodule DriversSeatCoop.Repo.Migrations.CreateSegments do
  use Ecto.Migration

  def change do
    create table(:segments) do
      add(:activity_id, references(:activities, on_delete: :nothing))
      add(:cents_fee, :integer)
      add(:cents_irs_mileage_expense_p2, :integer)
      add(:cents_irs_mileage_expense_p3, :integer)
      add(:cents_irs_mileage_expense_total, :integer)
      add(:cents_pay, :integer)
      add(:cents_promotion, :integer)
      add(:cents_tip, :integer)
      add(:datetime_end, :utc_datetime)
      add(:datetime_start, :utc_datetime)
      add(:employer, :string)
      add(:miles_p2, :decimal)
      add(:miles_p3, :decimal)
      add(:miles_p3_argyle, :decimal)
      add(:miles_total, :decimal)
      add(:seconds_p2, :decimal)
      add(:seconds_p3, :decimal)
      add(:seconds_total, :decimal)
      add(:shift_id, references(:shifts, on_delete: :nothing))
      add(:status, :string)
      add(:tasks_total, :integer)
      add(:user_id, references(:users, on_delete: :nothing))

      timestamps()
    end

    create(unique_index(:segments, [:activity_id]))
    create(index(:segments, [:user_id]))
    create(index(:segments, [:shift_id]))
  end
end
