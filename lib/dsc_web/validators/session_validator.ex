defmodule DriversSeatCoopWeb.SessionValidator do
  alias Ecto.Changeset

  def create(params) do
    types = %{
      email: :string,
      password: :string
    }

    data = %{}

    changeset =
      {data, types}
      |> Changeset.cast(params, Map.keys(types))
      |> Changeset.validate_required([:email, :password])

    Changeset.apply_action(changeset, :insert)
  end
end
