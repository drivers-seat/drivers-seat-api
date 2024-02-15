defmodule DriversSeatCoop.Oban do
  @moduledoc """
  The Oban context.
  """

  import Ecto.Query, warn: false
  alias DriversSeatCoop.Repo
  import Torch.Helpers, only: [sort: 1, paginate: 4]
  import Filtrex.Type.Config

  @pagination [page_size: 15]
  @pagination_distance 5

  @doc """
  Paginate the list of oban_jobs using filtrex
  filters.

  ## Examples

      iex> list_oban_jobs(%{})
      %{oban_jobs: [%Job{}], ...}
  """
  @spec paginate_oban_jobs(map) :: {:ok, map} | {:error, any}
  def paginate_oban_jobs(params \\ %{}) do
    params =
      params
      |> Map.put_new("sort_direction", "desc")
      |> Map.put_new("sort_field", "inserted_at")

    {:ok, sort_direction} = Map.fetch(params, "sort_direction")
    {:ok, sort_field} = Map.fetch(params, "sort_field")

    with {:ok, filter} <- Filtrex.parse_params(filter_config(:oban_jobs), params["job"] || %{}),
         %Scrivener.Page{} = page <- do_paginate_oban_jobs(filter, params) do
      {:ok,
       %{
         oban_jobs: page.entries,
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

  defp do_paginate_oban_jobs(filter, params) do
    Oban.Job
    |> Filtrex.query(filter)
    |> order_by(^sort(params))
    |> paginate(Repo, params, @pagination)
  end

  @doc """
  Returns the list of oban_jobs.

  ## Examples

      iex> list_oban_jobs()
      [%Job{}, ...]

  """
  def list_oban_jobs do
    Repo.all(Oban.Job)
  end

  @doc """
  Gets a single job.

  Raises `Ecto.NoResultsError` if the Job does not exist.

  ## Examples

      iex> get_job!(123)
      %Job{}

      iex> get_job!(456)
      ** (Ecto.NoResultsError)

  """
  def get_job!(id), do: Repo.get!(Oban.Job, id)

  @doc """
  Deletes a Job.

  ## Examples

      iex> delete_job(job)
      {:ok, %Job{}}

      iex> delete_job(job)
      {:error, %Ecto.Changeset{}}

  """
  def delete_job(%Oban.Job{} = job) do
    Repo.delete(job)
  end

  defp filter_config(:oban_jobs) do
    defconfig do
      text(:state)
      text(:queue)
      text(:worker)
      text(:args)
      text(:errors)
      number(:attempt)
      number(:max_attempts)
      date(:inserted_at)
      date(:scheduled_at)
      date(:attempted_at)
      date(:completed_at)
      text(:attempted_by)
      date(:discarded_at)
      number(:priority)
      date(:cancelled_at)
    end
  end
end
