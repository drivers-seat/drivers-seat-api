defmodule DriversSeatCoop.Goals.GoalFrequency do
  use EctoEnum,
    type: :goal_frequency,
    enums: [:day, :week, :month]
end
