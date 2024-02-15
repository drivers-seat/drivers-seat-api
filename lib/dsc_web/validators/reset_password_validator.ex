defmodule DriversSeatCoopWeb.ResetPasswordValidator do
  alias Ecto.Changeset

  def create(params) do
    types = %{
      email: :string
    }

    data = %{}

    changeset =
      {data, types}
      |> Changeset.cast(params, Map.keys(types))
      |> Changeset.validate_required([:email])

    Changeset.apply_action(changeset, :insert)
  end
end
