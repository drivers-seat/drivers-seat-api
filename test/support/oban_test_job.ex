defmodule DriversSeatCoop.ObanTestJob do
  use Oban.Worker,
    queue: :argyle_api

  def schedule_job do
    new(%{})
    |> Oban.insert()
  end

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    # do nothing
    :ok
  end

  @impl Oban.Worker
  def timeout(_job), do: :timer.minutes(30)
end
