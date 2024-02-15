defmodule DriversSeatCoopWeb.Admin.TermsController do
  use DriversSeatCoopWeb, :controller

  alias DriversSeatCoop.Legal
  alias DriversSeatCoop.Legal.Terms

  plug(:put_layout, {DriversSeatCoopWeb.LayoutView, "torch.html"})

  def index(conn, params) do
    case Legal.paginate_terms(params) do
      {:ok, assigns} ->
        render(conn, "index.html", assigns)

      error ->
        conn
        |> put_flash(:error, "There was an error rendering Terms. #{inspect(error)}")
        |> redirect(to: Routes.admin_terms_path(conn, :index))
    end
  end

  def new(conn, _params) do
    changeset = Legal.change_terms(%Terms{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"terms" => terms_params}) do
    case Legal.create_terms(terms_params, conn.assigns.user.id) do
      {:ok, terms} ->
        conn
        |> put_flash(:info, "Terms created successfully.")
        |> redirect(to: Routes.admin_terms_path(conn, :show, terms))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    terms = Legal.get_terms!(id)
    render(conn, "show.html", terms: terms)
  end

  def edit(conn, %{"id" => id}) do
    terms = Legal.get_terms!(id)
    changeset = Legal.change_terms(terms)
    render(conn, "edit.html", terms: terms, changeset: changeset)
  end

  def update(conn, %{"id" => id, "terms" => terms_params}) do
    terms = Legal.get_terms!(id)

    case Legal.update_terms(terms, terms_params) do
      {:ok, terms} ->
        conn
        |> put_flash(:info, "Terms updated successfully.")
        |> redirect(to: Routes.admin_terms_path(conn, :show, terms))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", terms: terms, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    terms = Legal.get_terms!(id)
    {:ok, _terms} = Legal.delete_terms(terms)

    conn
    |> put_flash(:info, "Terms deleted successfully.")
    |> redirect(to: Routes.admin_terms_path(conn, :index))
  end
end
