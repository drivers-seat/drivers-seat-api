defmodule DriversSeatCoop.DevicesTest do
  use DriversSeatCoop.DataCase, async: true

  alias DriversSeatCoop.Devices
  alias DriversSeatCoop.Devices.Device
  alias DriversSeatCoop.Repo

  describe "query" do
    test "filter user - single" do
      user_1 = Factory.create_user()

      device_u1_d1 =
        Factory.create_device(user_1.id, "TEST1", %{
          app_version: "1.0.0"
        }).id

      device_u1_d2 =
        Factory.create_device(user_1.id, "TEST2", %{
          app_version: "1.0.1"
        }).id

      user_2 = Factory.create_user()

      device_u2_d1 =
        Factory.create_device(user_2.id, "TEST1", %{
          app_version: "1.0.0"
        }).id

      all_devices =
        Devices.query()
        |> select([d], d.id)
        |> Repo.all()
        |> Enum.sort()

      user_1_devices =
        Devices.query()
        |> Devices.query_filter_user(user_1.id)
        |> select([d], d.id)
        |> Repo.all()
        |> Enum.sort()

      assert all_devices == [device_u1_d1, device_u1_d2, device_u2_d1]
      assert user_1_devices == [device_u1_d1, device_u1_d2]
    end

    test "filter user - multiple" do
      user_1 = Factory.create_user()

      device_u1_d1 =
        Factory.create_device(user_1.id, "TEST1", %{
          app_version: "1.0.0"
        }).id

      device_u1_d2 =
        Factory.create_device(user_1.id, "TEST2", %{
          app_version: "1.0.1"
        }).id

      user_2 = Factory.create_user()

      device_u2_d1 =
        Factory.create_device(user_2.id, "TEST1", %{
          app_version: "1.0.0"
        }).id

      user_3 = Factory.create_user()

      _device_u3_d1 =
        Factory.create_device(user_3.id, "TEST1", %{
          app_version: "1.0.0"
        }).id

      user_1_2_devices =
        Devices.query()
        |> Devices.query_filter_user([user_1.id, user_2.id])
        |> select([d], d.id)
        |> Repo.all()
        |> Enum.sort()

      assert user_1_2_devices == [device_u1_d1, device_u1_d2, device_u2_d1]
    end

    test "filter app version - single" do
      user_1 = Factory.create_user()

      device_u1_d1 =
        Factory.create_device(user_1.id, "TEST1", %{
          app_version: "1.0.0"
        }).id

      _device_u1_d2 =
        Factory.create_device(user_1.id, "TEST2", %{
          app_version: "1.0.1"
        }).id

      user_2 = Factory.create_user()

      device_u2_d1 =
        Factory.create_device(user_2.id, "TEST3", %{
          app_version: "1.0.0"
        }).id

      _device_u2_d2 =
        Factory.create_device(user_2.id, "TEST4", %{
          app_version: "1.0.1"
        }).id

      devices =
        Devices.query()
        |> Devices.query_filter_app_version("1.0.0")
        |> select([d], d.id)
        |> Repo.all()
        |> Enum.sort()

      assert devices == [device_u1_d1, device_u2_d1]
    end

    test "filter app version - multiple" do
      user_1 = Factory.create_user()

      device_u1_d1 =
        Factory.create_device(user_1.id, "TEST1", %{
          app_version: "1.0.0"
        }).id

      device_u1_d2 =
        Factory.create_device(user_1.id, "TEST2", %{
          app_version: "1.0.1"
        }).id

      user_2 = Factory.create_user()

      device_u2_d1 =
        Factory.create_device(user_2.id, "TEST3", %{
          app_version: "1.0.0"
        }).id

      _device_u2_d2 =
        Factory.create_device(user_2.id, "TEST4", %{
          app_version: "1.0.3"
        }).id

      devices =
        Devices.query()
        |> Devices.query_filter_app_version(["1.0.0", "1.0.1"])
        |> select([d], d.id)
        |> Repo.all()
        |> Enum.sort()

      assert devices == [device_u1_d1, device_u1_d2, device_u2_d1]
    end

    test "honors update_last_access_date parameter" do
      user = Factory.create_user()

      device =
        Factory.create_device(user.id, "TEST1", %{
          last_access_date: ~D[2020-01-01]
        })

      actual_device = Devices.get_or_update!(user.id, "TEST1", %{}, false)

      assert device == actual_device

      expected_device = Map.put(device, :last_access_date, Date.utc_today())
      actual_device = Devices.get_or_update!(user.id, "TEST1", %{}, true)

      assert expected_device == actual_device
    end
  end

  describe "get prod devices" do
    test "works correctly" do
      dsc_user_1 =
        Factory.create_user(%{
          email: "test@driversseat.co"
        })

      _device_u1_d1 =
        Factory.create_device(dsc_user_1.id, "GHOST1", %{
          app_version: "1.0.0"
        })

      dsc_user_2 =
        Factory.create_user(%{
          email: "test@rokkincat.co"
        })

      _device_u2_d1 =
        Factory.create_device(dsc_user_2.id, "GHOST2", %{
          app_version: "1.0.0"
        })

      dsc_user_3 =
        Factory.create_user(%{
          email: "test@acme.com"
        })

      _device_u3_d1 =
        Factory.create_device(dsc_user_3.id, "TEST1", %{
          app_version: "1.0.0"
        })

      _device_u3_d2 =
        Factory.create_device(dsc_user_3.id, "GHOST1", %{
          app_version: "1.0.0"
        })

      device_grps =
        Devices.prod_devices_qry()
        |> Repo.all()
        |> Enum.group_by(fn d -> d.device_id end)

      # all of the devices are represented
      assert Enum.sort(Map.keys(device_grps)) == ["GHOST1", "GHOST2", "TEST1"]

      # filtering ghost devices works
      assert Enum.all?(Map.values(device_grps), fn x -> Enum.count(x) == 1 end)

      # picks the correct user for ghost device, does not pick the non-prod user for the ghost device
      assert Map.get(device_grps, "GHOST1")
             |> Enum.map(fn d -> d.user_id end) == [dsc_user_1.id]
    end
  end

  describe "device test" do
    test "get_clean_version" do
      assert Device.get_clean_version("3.0.0") == "3.0.0"
      assert Device.get_clean_version(" 3.0 .0 ") == "3.0.0"
      assert Device.get_clean_version("3.0.0.127") == "3.0.0"
      assert Device.get_clean_version("3.0") == "3.0.0"
      assert Device.get_clean_version("3.0.1 Android") == "3.0.1"
      assert Device.get_clean_version("") == "0.0.0"
    end

    test "is_version_match?" do
      assert Device.is_version_match?("3.0.0", ">= 3.0.0") == true
      assert Device.is_version_match?("3.0.0", "> 3.0.0") == false
      assert Device.is_version_match?("3.0.0", "<= 3.0.0") == true
      assert Device.is_version_match?("3.0.0", "< 3.0.0") == false
      assert Device.is_version_match?("3.0.0", "== 3.0.0") == true
    end

    test "compare_version" do
      assert Device.compare_version("3.0.0", "3.0.0") == :eq
      assert Device.compare_version("3.0.0", "3.0.1") == :lt
      assert Device.compare_version("3.0.0", "2.0.0") == :gt
      assert Device.compare_version("3.1.2", "3.10.3") == :lt
      assert Device.compare_version("3.0.0 Android", "3.0.0 iOs") == :eq
    end
  end
end
