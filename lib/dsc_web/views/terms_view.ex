defmodule DriversSeatCoopWeb.TermsView do
  use DriversSeatCoopWeb, :view

  def render("show.json", %{terms: terms}) do
    %{data: render("terms.json", %{terms: terms})}
  end

  def render("terms.json", %{terms: nil}) do
    nil
  end

  def render("terms.json", %{terms: terms}) do
    %{
      id: terms.id,
      accepted_terms: render_accepted_terms(terms.accepted_terms),
      required_at: terms.required_at,
      text: terms.text,
      title: terms.title
    }
  end

  @doc """
  Renders the terms, the current accepted terms, future terms, and future accepted terms
  as siblings instead of parent/children as it's easier for the app to handle with this
  structure.
  """
  def render("current.json", %{current: current_terms, future: future_terms}) do
    {current, current_accepted} = render_terms_as_siblings(current_terms)
    {future, future_accepted} = render_terms_as_siblings(future_terms)

    %{
      data: %{
        current_accepted_terms: current_accepted,
        current_terms: current,
        future_accepted_terms: future_accepted,
        future_terms: future
      }
    }
  end

  def render_terms_as_siblings(nil) do
    {nil, nil}
  end

  def render_terms_as_siblings(terms) do
    rendered_terms = %{
      id: terms.id,
      required_at: terms.required_at,
      text: terms.text,
      title: terms.title
    }

    rendered_accepted = render_accepted_terms(terms.accepted_terms)
    {rendered_terms, rendered_accepted}
  end

  defp render_accepted_terms([accepted_terms]) do
    %{
      id: accepted_terms.id,
      accepted_at: accepted_terms.accepted_at,
      terms_id: accepted_terms.terms_id
    }
  end

  defp render_accepted_terms(_), do: nil
end
