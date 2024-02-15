defmodule DriversSeatCoop.CommunityInsights.CoverageStatsSource do
  use EctoEnum,
    type: :coverage_stats_source,
    enums: [:query, :metro]
end
