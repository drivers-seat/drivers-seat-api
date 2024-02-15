defmodule DriversSeatCoop.TestHelpers do
  def put_auth_header(conn, user) do
    token = DriversSeatCoop.Accounts.token_for_user_id(user.id)
    put_header(conn, "authorization", "Bearer #{token}")
  end

  def put_admin_session(conn, user) do
    Plug.Test.init_test_session(conn, %{user_id: user.id})
  end

  def put_device_id_header(conn, device_id) do
    put_header(conn, "dsc-device-id", device_id)
  end

  defp put_header(conn, key, value) do
    Plug.Conn.put_req_header(conn, key, value)
  end
end
