defmodule DriversSeatCoopWeb.TermsController do
  use DriversSeatCoopWeb, :controller

  alias DriversSeatCoop.Legal

  def current(conn, _params) do
    time = NaiveDateTime.utc_now()
    user_id = conn.assigns.user.id

    current_terms = Legal.get_current_terms_required_by_for_user_id(time, user_id)
    future_terms = Legal.get_future_terms_required_by_for_user_id(time, user_id)

    render(conn, "current.json", current: current_terms, future: future_terms)
  end

  def show(conn, %{"id" => id}) do
    terms = Legal.get_terms_with_accepted_terms_for_user!(id, conn.assigns.user.id)

    render(conn, "show.json", terms: terms)
  end

  def public(conn, _params) do
    current_terms = Legal.get_current_term()

    render(conn, "show.json", terms: current_terms)
  end
end
