defmodule DriversSeatCoop.Research do
  @moduledoc """
  The Research context.
  """

  import Ecto.Query, warn: false

  alias DriversSeatCoop.Repo
  alias DriversSeatCoop.Research.FocusGroupMembership
  alias DriversSeatCoop.Research.ResearchGroup

  @doc """
  Returns the list of research_groups.

  ## Examples

      iex> list_research_groups()
      [%ResearchGroup{}, ...]

  """
  def list_research_groups do
    Repo.all(ResearchGroup)
  end

  @doc """
  Gets a single research_group.

  Raises `Ecto.NoResultsError` if the Research group does not exist.

  ## Examples

      iex> get_research_group!(123)
      %ResearchGroup{}

      iex> get_research_group!(456)
      ** (Ecto.NoResultsError)

  """
  def get_research_group!(id), do: Repo.get!(ResearchGroup, id)

  def get_research_group_by_case_insensitive_code(code) do
    from(rg in ResearchGroup,
      where: fragment("lower(?) = lower(?)", rg.code, ^code)
    )
    |> Repo.one()
  end

  @doc """
  Creates a research_group.

  ## Examples

      iex> create_research_group(%{field: value})
      {:ok, %ResearchGroup{}}

      iex> create_research_group(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_research_group(attrs \\ %{}) do
    %ResearchGroup{}
    |> ResearchGroup.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a research_group.

  ## Examples

      iex> update_research_group(research_group, %{field: new_value})
      {:ok, %ResearchGroup{}}

      iex> update_research_group(research_group, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_research_group(%ResearchGroup{} = research_group, attrs) do
    research_group
    |> ResearchGroup.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a research_group.

  ## Examples

      iex> delete_research_group(research_group)
      {:ok, %ResearchGroup{}}

      iex> delete_research_group(research_group)
      {:error, %Ecto.Changeset{}}

  """
  def delete_research_group(%ResearchGroup{} = research_group) do
    Repo.delete(research_group)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking research_group changes.

  ## Examples

      iex> change_research_group(research_group)
      %Ecto.Changeset{source: %ResearchGroup{}}

  """
  def change_research_group(%ResearchGroup{} = research_group) do
    ResearchGroup.changeset(research_group, %{})
  end

  def get_current_membership(user_id) do
    from(e in FocusGroupMembership,
      where: e.user_id == ^user_id,
      where: is_nil(e.unenroll_date),
      limit: 1
    )
    |> Repo.one()
  end

  def unenroll_user(user_id) do
    Ecto.Multi.new()
    |> unenroll_user(user_id)
    |> Repo.transaction()
  end

  def unenroll_user(multi, user_id) do
    qry =
      from(e in FocusGroupMembership,
        where: e.user_id == ^user_id,
        where: is_nil(e.unenroll_date)
      )

    Ecto.Multi.update_all(multi, "unenroll", qry,
      set: [
        unenroll_date: DateTime.utc_now(),
        updated_at: DateTime.utc_now()
      ]
    )
  end

  def enroll_user(multi, user_id, focus_group_id) do
    membership = %FocusGroupMembership{
      user_id: user_id,
      focus_group_id: focus_group_id
    }

    attrs = %{
      enroll_date: DateTime.utc_now()
    }

    changeset = FocusGroupMembership.changeset(membership, attrs)

    Ecto.Multi.insert(multi, "enroll #{focus_group_id}", changeset, on_conflict: :nothing)
  end

  def query_membership, do: from(m in FocusGroupMembership)

  def query_membership_filter_active(qry), do: where(qry, [m], is_nil(m.unenroll_date))

  def query_membership_filter_groups(qry, group_id_or_ids) do
    group_id_or_ids = List.wrap(group_id_or_ids)
    where(qry, [m], m.focus_group_id in ^group_id_or_ids)
  end

  def query_membership_filter_users(qry, user_id_or_ids) do
    user_id_or_ids = List.wrap(user_id_or_ids)
    where(qry, [m], m.user_id in ^user_id_or_ids)
  end
end
