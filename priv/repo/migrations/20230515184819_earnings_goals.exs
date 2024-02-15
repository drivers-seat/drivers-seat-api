defmodule DriversSeatCoop.Repo.Migrations.EarningsGoals do
  use Ecto.Migration
  alias DriversSeatCoop.Goals.GoalFrequency
  alias DriversSeatCoop.Goals.GoalType

  def change do
    GoalType.create_type()
    GoalFrequency.create_type()

    create table(:goals) do
      add(:user_id, references(:users, on_delete: :nothing), null: false)
      add(:type, :goal_type, null: false)
      add(:frequency, :goal_frequency, null: false)
      add(:sub_frequency, :citext, null: false, default: "all")
      add(:start_date, :date, null: false)
      add(:amount, :integer, null: false)
      timestamps()
    end

    create unique_index(:goals, [:user_id, :type, :frequency, :start_date, :sub_frequency],
             name: :goals_unique_key
           )

    create table(:goal_measurements) do
      add(:user_id, references(:users, on_delete: :nothing), null: false)
      add(:goal_id, references(:goals, on_delete: :nothing), null: false)
      add(:window_date, :date, null: false)
      add(:performance_amount, :integer, null: false)
      add(:performance_percent, :decimal, null: false)
      add(:additional_info, :map)
      timestamps()
    end

    create unique_index(:goal_measurements, [:user_id, :goal_id, :window_date],
             name: :goal_measurements_user_key
           )

    create unique_index(:goal_measurements, [:goal_id, :window_date], name: :goal_measurements_key)
  end
end
