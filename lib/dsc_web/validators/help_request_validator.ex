defmodule DriversSeatCoopWeb.HelpRequestValidator do
  alias Ecto.Changeset

  def create(params) do
    types = %{
      email: :string,
      name: :string,
      subject: :string,
      message: :string
    }

    changeset =
      {%{}, types}
      |> Changeset.cast(params, Map.keys(types))
      |> Changeset.validate_required(Map.keys(types))

    Changeset.apply_action(changeset, :insert)
  end
end
