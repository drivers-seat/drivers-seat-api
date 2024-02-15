defmodule DriversSeatCoop.Legal do
  @moduledoc """
  The Legal context.
  """

  import Ecto.Query, warn: false
  alias DriversSeatCoop.Repo
  import Torch.Helpers, only: [sort: 1, paginate: 4]
  import Filtrex.Type.Config

  alias DriversSeatCoop.Legal.{AcceptedTerms, Terms}

  @pagination [page_size: 15]
  @pagination_distance 5

  @doc """
  Paginate the list of terms using filtrex
  filters.

  ## Examples

      iex> list_terms(%{})
      %{terms: [%Terms{}], ...}
  """
  @spec paginate_terms(map) :: {:ok, map} | {:error, any}
  def paginate_terms(params \\ %{}) do
    params =
      params
      |> Map.put_new("sort_direction", "desc")
      |> Map.put_new("sort_field", "inserted_at")

    {:ok, sort_direction} = Map.fetch(params, "sort_direction")
    {:ok, sort_field} = Map.fetch(params, "sort_field")

    with {:ok, filter} <- Filtrex.parse_params(terms_filter_config(), params["terms"] || %{}),
         %Scrivener.Page{} = page <- do_paginate_terms(filter, params) do
      {:ok,
       %{
         terms: page.entries,
         page_number: page.page_number,
         page_size: page.page_size,
         total_pages: page.total_pages,
         total_entries: page.total_entries,
         distance: @pagination_distance,
         sort_field: sort_field,
         sort_direction: sort_direction
       }}
    else
      {:error, error} -> {:error, error}
      error -> {:error, error}
    end
  end

  defp do_paginate_terms(filter, params) do
    Terms
    |> Filtrex.query(filter)
    |> order_by(^sort(params))
    |> paginate(Repo, params, @pagination)
  end

  @doc """
  Returns the list of terms.

  ## Examples

      iex> list_terms()
      [%Terms{}, ...]

  """
  def list_terms do
    Repo.all(Terms)
  end

  @doc """
  Gets a single terms.

  Raises `Ecto.NoResultsError` if the Terms does not exist.

  ## Examples

      iex> get_terms!(123)
      %Terms{}

      iex> get_terms!(456)
      ** (Ecto.NoResultsError)

  """
  def get_terms!(id), do: Repo.get!(Terms, id)

  def get_terms_with_accepted_terms_for_user!(id, user_id) do
    from(t in Terms,
      where: t.id == ^id,
      left_join: at in AcceptedTerms,
      on: at.terms_id == t.id and at.user_id == ^user_id,
      preload: [accepted_terms: at],
      order_by: [desc: t.required_at],
      limit: 1
    )
    |> Repo.one!()
  end

  def get_current_terms_required_by_for_user_id(required_by, user_id) do
    from(t in Terms,
      where: t.required_at <= ^required_by,
      left_join: at in AcceptedTerms,
      on: at.terms_id == t.id and at.user_id == ^user_id,
      preload: [accepted_terms: at],
      order_by: [desc: t.required_at],
      limit: 1
    )
    |> Repo.one()
  end

  def get_current_term do
    now = NaiveDateTime.utc_now()

    from(t in Terms,
      where: t.required_at <= ^now,
      order_by: [desc: t.required_at],
      limit: 1
    )
    |> Repo.one()
  end

  def get_future_terms_required_by_for_user_id(required_by, user_id) do
    from(t in Terms,
      where: t.required_at > ^required_by,
      left_join: at in AcceptedTerms,
      on: at.terms_id == t.id and at.user_id == ^user_id,
      preload: [accepted_terms: at],
      order_by: [desc: t.required_at],
      limit: 1
    )
    |> Repo.one()
  end

  @doc """
  Creates a terms.

  ## Examples

      iex> create_terms(%{field: value})
      {:ok, %Terms{}}

      iex> create_terms(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_terms(attrs, user_id) do
    %Terms{user_id: user_id}
    |> Terms.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a terms.

  ## Examples

      iex> update_terms(terms, %{field: new_value})
      {:ok, %Terms{}}

      iex> update_terms(terms, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_terms(%Terms{} = terms, attrs) do
    terms
    |> Terms.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Terms.

  ## Examples

      iex> delete_terms(terms)
      {:ok, %Terms{}}

      iex> delete_terms(terms)
      {:error, %Ecto.Changeset{}}

  """
  def delete_terms(%Terms{} = terms) do
    Repo.delete(terms)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking terms changes.

  ## Examples

      iex> change_terms(terms)
      %Ecto.Changeset{source: %Terms{}}

  """
  def change_terms(%Terms{} = terms) do
    Terms.changeset(terms, %{})
  end

  defp terms_filter_config do
    defconfig do
      text(:title)
      text(:text)
      date(:required_at)
    end
  end

  @doc """
  Paginate the list of accepted_terms using filtrex
  filters.

  ## Examples

  iex> list_accepted_terms(%{})
  %{accepted_terms: [%AcceptedTerms{}], ...}
  """
  @spec paginate_accepted_terms(map) :: {:ok, map} | {:error, any}
  def paginate_accepted_terms(params \\ %{}) do
    params =
      params
      |> Map.put_new("sort_direction", "desc")
      |> Map.put_new("sort_field", "inserted_at")

    {:ok, sort_direction} = Map.fetch(params, "sort_direction")
    {:ok, sort_field} = Map.fetch(params, "sort_field")

    with {:ok, filter} <-
           Filtrex.parse_params(accepted_terms_filter_config(), params["accepted_terms"] || %{}),
         %Scrivener.Page{} = page <- do_paginate_accepted_terms(filter, params) do
      {:ok,
       %{
         accepted_terms: page.entries,
         page_number: page.page_number,
         page_size: page.page_size,
         total_pages: page.total_pages,
         total_entries: page.total_entries,
         distance: @pagination_distance,
         sort_field: sort_field,
         sort_direction: sort_direction
       }}
    else
      {:error, error} -> {:error, error}
      error -> {:error, error}
    end
  end

  defp do_paginate_accepted_terms(filter, params) do
    AcceptedTerms
    |> Filtrex.query(filter)
    |> order_by(^sort(params))
    |> paginate(Repo, params, @pagination)
  end

  @doc """
  Returns the list of accepted_terms.

  ## Examples

  iex> list_accepted_terms()
  [%AcceptedTerms{}, ...]

  """
  def list_accepted_terms do
    Repo.all(AcceptedTerms)
  end

  def list_accepted_terms_by_user_id(user_id) do
    from(at in AcceptedTerms,
      where: at.user_id == ^user_id,
      order_by: [desc: :accepted_at],
      preload: [:terms]
    )
    |> Repo.all()
  end

  @doc """
  Gets a single accepted_terms.

  Raises `Ecto.NoResultsError` if the Accepted terms does not exist.

  ## Examples

  iex> get_accepted_terms!(123)
  %AcceptedTerms{}

  iex> get_accepted_terms!(456)
  ** (Ecto.NoResultsError)

  """
  def get_accepted_terms!(id), do: Repo.get!(AcceptedTerms, id)

  def get_accepted_terms(id) do
    from(at in AcceptedTerms,
      where: at.id == ^id,
      preload: [:terms],
      limit: 1
    )
    |> Repo.one()
  end

  def get_accepted_terms_by_terms_id_and_user_id(terms_id, user_id) do
    Repo.get_by(AcceptedTerms, terms_id: terms_id, user_id: user_id)
  end

  def preload_terms(%AcceptedTerms{} = accepted_terms) do
    Repo.preload(accepted_terms, [:terms])
  end

  @doc """
  Creates a accepted_terms.

  ## Examples

  iex> create_accepted_terms(%{field: value})
  {:ok, %AcceptedTerms{}}

  iex> create_accepted_terms(%{field: bad_value})
  {:error, %Ecto.Changeset{}}

  """
  def create_accepted_terms(attrs, user_id, accepted_at) do
    accepted_at = NaiveDateTime.truncate(accepted_at, :second)

    # the on_conflict setting will allow already accepted terms to be silently
    # accepted again. this simplifies the logic in the app. the replace &
    # returning setting ensures that the full record is returned in the event of
    # a conflict
    %AcceptedTerms{user_id: user_id, accepted_at: accepted_at}
    |> AcceptedTerms.changeset(attrs)
    |> Repo.insert(
      on_conflict: {:replace, [:updated_at]},
      conflict_target: [:user_id, :terms_id],
      returning: true
    )
  end

  def admin_create_accepted_terms(attrs) do
    %AcceptedTerms{}
    |> AcceptedTerms.admin_changeset(attrs)
    |> Repo.insert()
  end

  def admin_update_accepted_terms(%AcceptedTerms{} = accepted_terms, attrs) do
    accepted_terms
    |> AcceptedTerms.admin_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a AcceptedTerms.

  ## Examples

  iex> delete_accepted_terms(accepted_terms)
  {:ok, %AcceptedTerms{}}

  iex> delete_accepted_terms(accepted_terms)
      {:error, %Ecto.Changeset{}}

  """
  def delete_accepted_terms(%AcceptedTerms{} = accepted_terms) do
    Repo.delete(accepted_terms)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking accepted_terms changes.

  ## Examples

      iex> change_accepted_terms(accepted_terms)
      %Ecto.Changeset{source: %AcceptedTerms{}}

  """
  def change_accepted_terms(%AcceptedTerms{} = accepted_terms) do
    AcceptedTerms.changeset(accepted_terms, %{})
  end

  @doc """
  Returns :ok if user has agreed to latest terms or {:error, {:new_terms, %Terms{}}}
  if they have not.
  """
  @spec user_has_agreed_to_latest_terms_by(User.t(), NaiveDateTime.t()) ::
          :ok | {:error, {:new_terms, Terms.t()}}
  def user_has_agreed_to_latest_terms_by(user, naive_date_time) do
    user_id = user.id

    terms =
      from(t in Terms,
        left_join: at in AcceptedTerms,
        on: at.terms_id == t.id and at.user_id == ^user_id,
        where: t.required_at <= ^naive_date_time,
        order_by: [desc: t.required_at],
        preload: [accepted_terms: at],
        limit: 1
      )
      |> Repo.one()

    case terms do
      # No terms required at the moment
      nil ->
        :ok

      # Found a Terms and user has accepted them.
      %Terms{accepted_terms: [%AcceptedTerms{user_id: ^user_id}]} ->
        :ok

      # Found a Terms and user has not accepted them.
      %Terms{accepted_terms: []} = terms ->
        {:error, {:new_terms, terms}}
    end
  end

  defp accepted_terms_filter_config do
    defconfig do
      date(:accepted_at)
    end
  end
end
