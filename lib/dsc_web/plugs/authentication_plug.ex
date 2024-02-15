defmodule DriversSeatCoopWeb.AuthenticationPlug do
  @behaviour Plug
  import Plug.Conn, only: [get_req_header: 2, assign: 3, put_status: 2, halt: 1]

  def init(__opts) do
    []
  end

  def call(conn, _opts) do
    req_header = get_req_header(conn, "authorization")

    req_header
    |> token_from_header()
    |> DriversSeatCoop.Accounts.verify_token()
    |> setup_session(conn)
  end

  defp token_from_header(["Bearer " <> token]) do
    token
  end

  defp token_from_header(_), do: nil

  defp setup_session({:ok, %{user_id: user_id}}, conn) do
    case DriversSeatCoop.Accounts.get_user(user_id) do
      nil -> authentication_error_response(conn)
      user -> put_user(conn, user)
    end
  end

  defp setup_session(_, conn) do
    authentication_error_response(conn)
  end

  defp authentication_error_response(conn) do
    conn
    |> put_status(:unauthorized)
    |> Phoenix.Controller.put_view(DriversSeatCoopWeb.ErrorView)
    |> Phoenix.Controller.render("401.json")
    |> halt()
  end

  def put_auth_header(conn, token) do
    Plug.Conn.put_resp_header(conn, "authorization", "Bearer #{token}")
  end

  def put_user(conn, user) do
    assign(conn, :user, user)
  end
end
