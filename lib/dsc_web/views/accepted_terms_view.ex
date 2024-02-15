defmodule DriversSeatCoopWeb.AcceptedTermsView do
  use DriversSeatCoopWeb, :view
  alias DriversSeatCoopWeb.AcceptedTermsView

  def render("index.json", %{accepted_terms: accepted_terms}) do
    %{data: render_many(accepted_terms, AcceptedTermsView, "accepted_terms.json")}
  end

  def render("show.json", %{accepted_terms: accepted_terms}) do
    %{data: render_one(accepted_terms, AcceptedTermsView, "accepted_terms.json")}
  end

  def render("accepted_terms.json", %{accepted_terms: accepted_terms}) do
    %{
      id: accepted_terms.id,
      accepted_at: accepted_terms.accepted_at,
      terms: %{
        id: accepted_terms.terms.id,
        required_at: accepted_terms.terms.required_at,
        text: accepted_terms.terms.text,
        title: accepted_terms.terms.title
      }
    }
  end
end
