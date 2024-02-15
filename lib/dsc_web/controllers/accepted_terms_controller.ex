defmodule DriversSeatCoopWeb.AcceptedTermsController do
  use DriversSeatCoopWeb, :controller

  alias DriversSeatCoop.Legal
  alias DriversSeatCoop.Legal.AcceptedTerms

  def index(conn, _params) do
    accepted_terms = Legal.list_accepted_terms_by_user_id(conn.assigns.user.id)

    render(conn, "index.json", accepted_terms: accepted_terms)
  end

  def create(conn, %{"accepted_terms" => accepted_terms_params}) do
    user_id = conn.assigns.user.id
    accepted_at = NaiveDateTime.utc_now()

    with {:ok, %AcceptedTerms{} = accepted_terms} <-
           Legal.create_accepted_terms(accepted_terms_params, user_id, accepted_at),
         accepted_terms <- Legal.preload_terms(accepted_terms) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.accepted_terms_path(conn, :show, accepted_terms))
      |> render("show.json", accepted_terms: accepted_terms)
    end
  end

  def show(conn, %{"id" => id}) do
    accepted_terms = Legal.get_accepted_terms(id)

    with :ok <- DriversSeatCoop.Authorizer.authorize(:show, accepted_terms, conn.assigns.user) do
      render(conn, "show.json", accepted_terms: accepted_terms)
    end
  end
end
