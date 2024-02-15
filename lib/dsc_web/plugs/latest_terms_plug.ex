defmodule DriversSeatCoopWeb.LatestTermsPlug do
  @moduledoc """
  This Plug fetches the most recent %Terms{} and returns an error if the
  current %User{} does not have an %AcceptedTerms{} for the most recent %Terms{}.

  A user must be logged in to run this Plug.
  """
  alias DriversSeatCoop.Legal
  import Plug.Conn

  def init(_), do: []

  def call(conn, _opts) do
    user = conn.assigns.user

    case Legal.user_has_agreed_to_latest_terms_by(user, NaiveDateTime.utc_now()) do
      :ok ->
        conn

      {:error, {:new_terms, terms}} ->
        return_legal_error(conn, terms)
    end
  end

  defp return_legal_error(conn, terms) do
    conn
    |> put_status(:unavailable_for_legal_reasons)
    |> Phoenix.Controller.put_view(DriversSeatCoopWeb.ErrorView)
    |> Phoenix.Controller.render("451.json", %{terms: terms})
    |> halt()
  end
end
