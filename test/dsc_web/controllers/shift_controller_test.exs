defmodule DriversSeatCoopWeb.ShiftControllerTest do
  use DriversSeatCoopWeb.ConnCase, async: true
  use Oban.Testing, repo: DriversSeatCoop.Repo
  alias DriversSeatCoop.Devices
  alias DriversSeatCoop.Earnings.Oban.UpdateTimeSpansForUserWorkday
  alias DriversSeatCoop.Shifts
  alias DriversSeatCoop.Shifts.Shift

  @create_attrs %{
    start_time: "2021-01-01 00:00:00"
  }

  @create_attrs_2 %{
    start_time: "2021-02-01 00:00:00"
  }

  @update_attrs %{
    start_time: "2021-01-02 00:00:00",
    end_time: "2021-01-02 14:00:00"
  }

  setup %{conn: conn} do
    user =
      Factory.create_user(%{
        timezone: "America/Los_Angeles"
      })

    conn =
      put_req_header(conn, "accept", "application/json")
      |> TestHelpers.put_auth_header(user)

    {:ok, conn: conn, user: user}
  end

  describe "index" do
    test "lists all shifts", %{conn: conn, user: user} do
      %Shift{id: shift_id} = Factory.create_shift(%{user_id: user.id})
      conn = get(conn, Routes.shift_path(conn, :index))
      assert [%{"id" => ^shift_id}] = json_response(conn, 200)["data"]
    end
  end

  describe "create shift" do
    test "renders shift when data is valid", %{conn: conn, user: user} do
      conn = post(conn, Routes.shift_path(conn, :create), shift: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.shift_path(conn, :show, id))

      assert %{
               "id" => id,
               "end_time" => nil,
               "start_time" => "2021-01-01T00:00:00Z",
               "frontend_mileage" => nil,
               "user_id" => user.id
             } == json_response(conn, 200)["data"]

      # nothing should get queued up because the shift has not ended
      refute_enqueued(worker: UpdateTimeSpansForUserWorkday)
    end

    test "associates device to shift when available", %{conn: conn, user: user} do
      # create shift with no device info
      conn0 = conn
      conn0 = post(conn0, Routes.shift_path(conn, :create), shift: @create_attrs)

      assert %{"id" => shift_id0} = json_response(conn0, 201)["data"]

      actual_shift0 = Shifts.get_shift!(shift_id0)

      assert is_nil(actual_shift0.device_id)

      # create shift with first device
      conn1 = TestHelpers.put_device_id_header(conn, "Device A")
      conn1 = post(conn1, Routes.shift_path(conn, :create), shift: @create_attrs)

      assert %{"id" => shift_id1} = json_response(conn1, 201)["data"]

      actual_device1 = Devices.get_for_user_by_device_id(user.id, "Device A")

      assert not is_nil(actual_device1)
      assert actual_device1.device_id == "device a"

      actual_shift1 = Shifts.get_shift!(shift_id1)

      assert actual_shift1.device_id == actual_device1.id

      # create shift with different device
      conn2 = TestHelpers.put_device_id_header(conn, "Device B")
      conn2 = post(conn2, Routes.shift_path(conn, :create), shift: @create_attrs)

      assert %{"id" => shift_id2} = json_response(conn2, 201)["data"]

      actual_device2 = Devices.get_for_user_by_device_id(user.id, "Device B")

      assert not is_nil(actual_device2)
      assert actual_device2.device_id == "device b"

      actual_shift2 = Shifts.get_shift!(shift_id2)

      assert actual_shift2.device_id == actual_device2.id

      # make sure that they are not the same device
      assert actual_device1.id != actual_device2.id
      assert actual_shift0.id != actual_shift1.id
      assert actual_shift0.id != actual_shift2.id
      assert actual_shift1.id != actual_shift2.id
    end

    test "does not allow multiple open shifts on same device", %{conn: conn} do
      # try to create 2 shifts with no device info, the same shift should return
      conn1 = conn
      conn1 = post(conn1, Routes.shift_path(conn1, :create), shift: @create_attrs)
      assert %{"id" => shift_id1} = json_response(conn1, 201)["data"]

      conn2 = conn
      conn2 = post(conn2, Routes.shift_path(conn2, :create), shift: @create_attrs_2)
      assert %{"id" => shift_id2} = json_response(conn2, 201)["data"]

      assert shift_id1 == shift_id2

      # try to create 2 shifts with no device info, the same shift should return
      conn3 = conn
      conn3 = TestHelpers.put_device_id_header(conn3, "Device A")
      conn3 = post(conn3, Routes.shift_path(conn3, :create), shift: @create_attrs)
      assert %{"id" => shift_id3} = json_response(conn3, 201)["data"]

      conn4 = conn
      conn4 = TestHelpers.put_device_id_header(conn4, "Device A")
      conn4 = post(conn4, Routes.shift_path(conn4, :create), shift: @create_attrs_2)
      assert %{"id" => shift_id4} = json_response(conn4, 201)["data"]

      assert shift_id1 == shift_id2
      assert shift_id3 == shift_id4
      assert shift_id1 != shift_id3
    end
  end

  describe "update shift" do
    test "renders shift when data is valid", %{conn: conn, user: user} do
      shift = %Shift{id: id} = Factory.create_shift(%{user_id: user.id})

      conn = put(conn, Routes.shift_path(conn, :update, shift), shift: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.shift_path(conn, :show, id))

      assert %{
               "id" => id,
               "end_time" => "2021-01-02T14:00:00Z",
               "start_time" => "2021-01-02T00:00:00Z",
               "frontend_mileage" => nil,
               "user_id" => user.id
             } == json_response(conn, 200)["data"]

      # rebuild earnings occurs for each day affected
      assert_enqueued(
        worker: UpdateTimeSpansForUserWorkday,
        args: %{
          user_id: user.id,
          work_date: "2021-01-01"
        }
      )

      assert_enqueued(
        worker: UpdateTimeSpansForUserWorkday,
        args: %{
          user_id: user.id,
          work_date: "2021-01-02"
        }
      )
    end
  end
end
