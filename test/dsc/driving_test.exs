defmodule DriversSeatCoop.DrivingTest do
  use DriversSeatCoop.DataCase, async: true

  alias DriversSeatCoop.Driving

  describe "points" do
    alias DriversSeatCoop.Driving.Point

    @valid_attrs %{
      recorded_at: ~N[2019-07-12 00:00:00.000000],
      latitude: 43,
      longitude: -89,
      status: "working"
    }
    @update_attrs %{
      recorded_at: ~N[2019-07-12 00:00:01.000000],
      latitude: 44,
      longitude: -88,
      status: "working"
    }
    @invalid_attrs %{recorded_at: nil, latitude: nil, longitude: nil, status: nil}

    test "list_points/0 returns all points" do
      %Point{id: id} = Factory.create_point()
      assert [%Point{id: ^id}] = Driving.list_points()
    end

    test "get_point!/1 returns the point with given id" do
      point = Factory.create_point()
      assert Driving.get_point!(point.id).id == point.id
    end

    test "create_point/2 with valid data creates a point" do
      user = Factory.create_user()
      valid_attrs = @valid_attrs
      assert {:ok, %Point{} = point} = Driving.create_point(valid_attrs, user.id)

      assert point.geometry == %Geo.Point{
               coordinates: {-89.0, 43.0},
               properties: %{},
               srid: 4326
             }

      assert point.recorded_at == ~U[2019-07-12 00:00:00.000000Z]
    end

    test "create_point/2 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Driving.create_point(@invalid_attrs, nil)
    end

    test "update_point/2 with valid data updates the point" do
      point = Factory.create_point()

      assert {:ok, %Point{} = point} = Driving.update_point(point, @update_attrs)

      assert point.geometry == %Geo.Point{
               coordinates: {-88.0, 44.0},
               properties: %{},
               srid: 4326
             }

      assert point.recorded_at == ~U[2019-07-12 00:00:01.000000Z]
    end

    test "update_point/2 with invalid data returns error changeset" do
      point = Factory.create_point()
      assert {:error, %Ecto.Changeset{}} = Driving.update_point(point, @invalid_attrs)

      assert Map.take(point, Map.keys(@invalid_attrs)) ==
               Map.take(Driving.get_point!(point.id), Map.keys(@invalid_attrs))
    end

    test "change_point/1 returns a point changeset" do
      point = Factory.create_point()
      assert %Ecto.Changeset{} = Driving.change_point(point)
    end

    test "query_points_by_user_id returns points" do
      user = Factory.create_user()
      [p1, p2, p3] = create_points(user)
      res = Driving.list_points_by_user_id(user.id)

      assert res == [
               %{
                 id: p3.id,
                 latitude: 42.0,
                 longitude: -64.0,
                 recorded_at: ~U[2022-02-17 01:03:01.000000Z],
                 user_id: user.id,
                 device_id: nil
               },
               %{
                 id: p2.id,
                 latitude: 34.0,
                 longitude: -64.0,
                 recorded_at: ~U[2022-02-17 01:02:01.000000Z],
                 user_id: user.id,
                 device_id: nil
               },
               %{
                 id: p1.id,
                 latitude: 30.0,
                 longitude: -70.0,
                 recorded_at: ~U[2022-02-17 01:01:01.000000Z],
                 user_id: user.id,
                 device_id: nil
               }
             ]
    end

    test "query_points_by_user_id applies limit" do
      user = Factory.create_user()
      [_p1, _p2, p3] = create_points(user)
      res = Driving.list_points_by_user_id(user.id, %{limit: 1})

      assert res == [
               %{
                 id: p3.id,
                 latitude: 42.0,
                 longitude: -64.0,
                 recorded_at: ~U[2022-02-17 01:03:01.000000Z],
                 user_id: user.id,
                 device_id: nil
               }
             ]
    end

    test "query_points_by_user_id applies start and end dates" do
      user = Factory.create_user()
      [_p1, p2, _p3] = create_points(user)

      res =
        Driving.list_points_by_user_id(user.id, %{
          date_start: ~N[2022-02-17 01:02:01.000000],
          date_end: ~N[2022-02-17 01:02:05.000000]
        })

      assert res == [
               %{
                 id: p2.id,
                 latitude: 34.0,
                 longitude: -64.0,
                 recorded_at: ~U[2022-02-17 01:02:01.000000Z],
                 user_id: user.id,
                 device_id: nil
               }
             ]
    end
  end

  defp create_points(user) do
    p1 =
      Factory.create_point(
        user_id: user.id,
        latitude: 30,
        longitude: -70,
        recorded_at: ~U[2022-02-17 01:01:01Z]
      )

    p3 =
      Factory.create_point(
        user_id: user.id,
        latitude: 42,
        longitude: -64,
        recorded_at: ~U[2022-02-17 01:03:01Z]
      )

    p2 =
      Factory.create_point(
        user_id: user.id,
        latitude: 34,
        longitude: -64,
        recorded_at: ~U[2022-02-17 01:02:01Z]
      )

    [p1, p2, p3]
  end

  describe "activities" do
    test "list_activity_ids_by_user_id returns nothing for a new user" do
      user = Factory.create_user()
      assert Driving.list_activity_ids_by_user_id(user.id) == []
    end

    test "list_activity_ids_by_user_id ignores deleted activities" do
      user = Factory.create_user()

      Factory.create_activity(%{
        "user_id" => user.id,
        "date" => ~U[2021-06-26 12:00:00Z],
        "deleted" => true
      })

      Factory.create_activity(%{
        "user_id" => user.id,
        "date" => ~U[2021-06-26 12:10:00Z],
        "deleted" => false
      })

      Factory.create_activity(%{
        "user_id" => user.id,
        "date" => ~U[2021-06-26 12:20:00Z],
        "deleted" => false
      })

      assert length(Driving.list_activity_ids_by_user_id(user.id)) == 2
    end
  end
end
