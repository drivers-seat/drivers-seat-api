defmodule DriversSeatCoopWeb.Admin.AcceptedTermsController do
  use DriversSeatCoopWeb, :controller

  alias DriversSeatCoop.Legal
  alias DriversSeatCoop.Legal.AcceptedTerms

  plug(:put_layout, {DriversSeatCoopWeb.LayoutView, "torch.html"})

  def index(conn, params) do
    case Legal.paginate_accepted_terms(params) do
      {:ok, assigns} ->
        render(conn, "index.html", assigns)

      error ->
        conn
        |> put_flash(:error, "There was an error rendering Accepted terms. #{inspect(error)}")
        |> redirect(to: Routes.admin_accepted_terms_path(conn, :index))
    end
  end

  def new(conn, _params) do
    changeset = Legal.change_accepted_terms(%AcceptedTerms{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"accepted_terms" => accepted_terms_params}) do
    case Legal.admin_create_accepted_terms(accepted_terms_params) do
      {:ok, accepted_terms} ->
        conn
        |> put_flash(:info, "Accepted terms created successfully.")
        |> redirect(to: Routes.admin_accepted_terms_path(conn, :show, accepted_terms))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    accepted_terms = Legal.get_accepted_terms!(id)
    render(conn, "show.html", accepted_terms: accepted_terms)
  end

  def edit(conn, %{"id" => id}) do
    accepted_terms = Legal.get_accepted_terms!(id)
    changeset = Legal.change_accepted_terms(accepted_terms)
    render(conn, "edit.html", accepted_terms: accepted_terms, changeset: changeset)
  end

  def update(conn, %{"id" => id, "accepted_terms" => accepted_terms_params}) do
    accepted_terms = Legal.get_accepted_terms!(id)

    case Legal.admin_update_accepted_terms(accepted_terms, accepted_terms_params) do
      {:ok, accepted_terms} ->
        conn
        |> put_flash(:info, "Accepted terms updated successfully.")
        |> redirect(to: Routes.admin_accepted_terms_path(conn, :show, accepted_terms))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", accepted_terms: accepted_terms, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    accepted_terms = Legal.get_accepted_terms!(id)
    {:ok, _accepted_terms} = Legal.delete_accepted_terms(accepted_terms)

    conn
    |> put_flash(:info, "Accepted terms deleted successfully.")
    |> redirect(to: Routes.admin_accepted_terms_path(conn, :index))
  end
end
