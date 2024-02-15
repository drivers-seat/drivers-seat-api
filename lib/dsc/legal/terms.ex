defmodule DriversSeatCoop.Legal.Terms do
  use Ecto.Schema
  import Ecto.Changeset

  @required_fields ~w(user_id text title)a
  @optional_fields ~w(required_at)a

  schema "terms" do
    field :required_at, :naive_datetime
    field :text, :string
    field :title, :string
    belongs_to :user, DriversSeatCoop.Accounts.User
    has_many :accepted_terms, DriversSeatCoop.Legal.AcceptedTerms

    timestamps()
  end

  @doc false
  def changeset(terms, attrs) do
    terms
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> assoc_constraint(:user)
  end
end
