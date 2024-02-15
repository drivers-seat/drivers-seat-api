defmodule DriversSeatCoop.ShiftsTest do
  use DriversSeatCoop.DataCase
  use Oban.Testing, repo: DriversSeatCoop.Repo

  alias DriversSeatCoop.Factory
  alias DriversSeatCoop.Shifts

  describe "shifts query" do
    test "filters for user" do
      u1 = Factory.create_user()

      u1_s1 =
        Factory.create_shift(%{
          user_id: u1.id
        })

      u2 = Factory.create_user()

      u2_s1 =
        Factory.create_shift(%{
          user_id: u2.id
        })

      actual_shifts_u1 =
        Shifts.query_shifts_for_user(u1.id)
        |> Repo.all()

      actual_shifts_u2 =
        Shifts.query_shifts_for_user(u2.id)
        |> Repo.all()

      assert [u1_s1] == actual_shifts_u1
      assert [u2_s1] == actual_shifts_u2
    end

    test "filters for date range" do
      u1 = Factory.create_user()

      u1_s1 =
        Factory.create_shift(%{
          user_id: u1.id,
          start_time: ~U[2023-01-01 02:00:00Z],
          end_time: ~U[2023-01-01 06:00:00Z]
        })

      _u1_s2 =
        Factory.create_shift(%{
          user_id: u1.id,
          start_time: ~U[2023-01-01 08:00:00Z],
          end_time: ~U[2023-01-01 10:00:00Z]
        })

      _u1_s3 =
        Factory.create_shift(%{
          user_id: u1.id,
          start_time: ~U[2023-01-01 08:00:00Z]
        })

      # Time Ranges within a shift
      actual =
        Shifts.query_shifts_for_user(u1.id)
        |> Shifts.query_shifts_filter_time_range(
          ~U[2023-01-01 03:00:00Z],
          ~U[2023-01-01 04:00:00Z]
        )
        |> Repo.all()

      assert actual == [u1_s1]

      # Time range starts before shift
      actual =
        Shifts.query_shifts_for_user(u1.id)
        |> Shifts.query_shifts_filter_time_range(
          ~U[2023-01-01 01:00:00Z],
          ~U[2023-01-01 04:00:00Z]
        )
        |> Repo.all()

      assert actual == [u1_s1]

      # Time range ends after shift
      actual =
        Shifts.query_shifts_for_user(u1.id)
        |> Shifts.query_shifts_filter_time_range(
          ~U[2023-01-01 04:00:00Z],
          ~U[2023-01-01 07:00:00Z]
        )
        |> Repo.all()

      assert actual == [u1_s1]

      # Time range extends before and after shift
      actual =
        Shifts.query_shifts_for_user(u1.id)
        |> Shifts.query_shifts_filter_time_range(
          ~U[2023-01-01 01:00:00Z],
          ~U[2023-01-01 07:00:00Z]
        )
        |> Repo.all()

      assert actual == [u1_s1]
    end

    test "includes open shifts in results" do
      u1 = Factory.create_user()

      _u1_s1 =
        Factory.create_shift(%{
          user_id: u1.id,
          start_time: ~U[2023-01-01 02:00:00Z],
          end_time: ~U[2023-01-01 06:00:00Z]
        })

      _u1_s2 =
        Factory.create_shift(%{
          user_id: u1.id,
          start_time: ~U[2023-01-01 08:00:00Z],
          end_time: ~U[2023-01-01 10:00:00Z]
        })

      u1_s3 =
        Factory.create_shift(%{
          user_id: u1.id,
          start_time: ~U[2023-01-01 12:00:00Z]
        })

      # Time Ranges within a shift
      actual =
        Shifts.query_shifts_for_user(u1.id)
        |> Shifts.query_shifts_filter_time_range(
          ~U[2023-01-01 13:00:00Z],
          ~U[2023-01-01 14:00:00Z]
        )
        |> Repo.all()

      assert actual == [u1_s3]

      # Time range starts before shift
      actual =
        Shifts.query_shifts_for_user(u1.id)
        |> Shifts.query_shifts_filter_time_range(
          ~U[2023-01-01 11:00:00Z],
          ~U[2023-01-01 14:00:00Z]
        )
        |> Repo.all()

      assert actual == [u1_s3]
    end

    test "ignores deleted shifts" do
      u1 = Factory.create_user()

      _u1_s1 =
        Factory.create_shift(%{
          user_id: u1.id,
          deleted: true
        })

      u1_s2 =
        Factory.create_shift(%{
          user_id: u1.id
        })

      actual =
        Shifts.query_shifts_for_user(u1.id)
        |> Repo.all()

      assert [u1_s2] == actual
    end
  end
end
