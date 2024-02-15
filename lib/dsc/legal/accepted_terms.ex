defmodule DriversSeatCoop.Legal.AcceptedTerms do
  use Ecto.Schema
  import Ecto.Changeset

  @required_fields ~w(terms_id user_id accepted_at)a
  @optional_fields ~w()a

  schema "accepted_terms" do
    field :accepted_at, :naive_datetime

    belongs_to :user, DriversSeatCoop.Accounts.User
    belongs_to :terms, DriversSeatCoop.Legal.Terms

    timestamps()
  end

  @doc false
  def changeset(accepted_terms, attrs) do
    accepted_terms
    |> cast(attrs, [:terms_id])
    |> validate_required(@required_fields)
    |> assoc_constraint(:user)
    |> assoc_constraint(:terms)
    |> unique_constraint(:terms_id, name: :accepted_terms_user_id_terms_id_index)
  end

  @doc false
  def admin_changeset(accepted_terms, attrs) do
    accepted_terms
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> assoc_constraint(:user)
    |> assoc_constraint(:terms)
    |> unique_constraint(:terms_id, name: :accepted_terms_user_id_terms_id_index)
  end
end
