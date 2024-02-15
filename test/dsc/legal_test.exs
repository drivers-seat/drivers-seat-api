defmodule DriversSeatCoop.LegalTest do
  use DriversSeatCoop.DataCase

  alias DriversSeatCoop.Legal

  describe "terms" do
    alias DriversSeatCoop.Legal.Terms

    @valid_attrs %{required_at: ~N[2010-04-17 14:00:00], text: "some text", title: "some title"}
    @update_attrs %{
      required_at: ~N[2011-05-18 15:01:01],
      text: "some updated text",
      title: "some updated title"
    }
    @invalid_attrs %{required_at: nil, text: nil, title: nil}

    test "list_terms/0 returns all terms" do
      terms = Factory.create_terms()
      assert Legal.list_terms() == [terms]
    end

    test "get_terms!/1 returns the terms with given id" do
      terms = Factory.create_terms()
      assert Legal.get_terms!(terms.id) == terms
    end

    test "create_terms/1 with valid data creates a terms" do
      user = Factory.create_user()
      assert {:ok, %Terms{} = terms} = Legal.create_terms(@valid_attrs, user.id)
      assert terms.required_at == ~N[2010-04-17 14:00:00]
      assert terms.text == "some text"
      assert terms.title == "some title"
    end

    test "create_terms/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Legal.create_terms(@invalid_attrs, nil)
    end

    test "update_terms/2 with valid data updates the terms" do
      terms = Factory.create_terms()
      assert {:ok, terms} = Legal.update_terms(terms, @update_attrs)
      assert %Terms{} = terms
      assert terms.required_at == ~N[2011-05-18 15:01:01]
      assert terms.text == "some updated text"
      assert terms.title == "some updated title"
    end

    test "update_terms/2 with invalid data returns error changeset" do
      terms = Factory.create_terms()
      assert {:error, %Ecto.Changeset{}} = Legal.update_terms(terms, @invalid_attrs)
      assert terms == Legal.get_terms!(terms.id)
    end

    test "delete_terms/1 deletes the terms" do
      terms = Factory.create_terms()
      assert {:ok, %Terms{}} = Legal.delete_terms(terms)
      assert_raise Ecto.NoResultsError, fn -> Legal.get_terms!(terms.id) end
    end

    test "change_terms/1 returns a terms changeset" do
      terms = Factory.create_terms()
      assert %Ecto.Changeset{} = Legal.change_terms(terms)
    end
  end

  describe "accepted_terms" do
    alias DriversSeatCoop.Legal.{AcceptedTerms, Terms}

    test "list_accepted_terms/0 returns all accepted_terms" do
      accepted_terms = Factory.create_accepted_terms()
      assert Legal.list_accepted_terms() == [accepted_terms]
    end

    test "get_accepted_terms!/1 returns the accepted_terms with given id" do
      accepted_terms = Factory.create_accepted_terms()
      assert Legal.get_accepted_terms!(accepted_terms.id) == accepted_terms
    end

    test "create_accepted_terms/1 with valid data creates a accepted_terms" do
      user = Factory.create_user()
      terms = Factory.create_terms()
      valid_attrs = %{terms_id: terms.id}
      accepted_at = ~N[2010-04-17 14:00:00]

      assert {:ok, %AcceptedTerms{} = accepted_terms} =
               Legal.create_accepted_terms(valid_attrs, user.id, accepted_at)

      assert accepted_terms.accepted_at == ~N[2010-04-17 14:00:00]
      assert accepted_terms.user_id == user.id
      assert accepted_terms.terms_id == terms.id
    end

    test "accepting the same terms more than once does not change accepted_at" do
      user = Factory.create_user()
      terms = Factory.create_terms()
      terms_id = terms.id
      accepted_at = ~N[2010-04-17 14:00:00]
      valid_attrs = Map.put(@valid_attrs, :terms_id, terms_id)

      assert {:ok, %AcceptedTerms{terms_id: ^terms_id}} =
               Legal.create_accepted_terms(valid_attrs, user.id, accepted_at)

      assert {:ok, %AcceptedTerms{terms_id: ^terms_id, accepted_at: ^accepted_at}} =
               Legal.create_accepted_terms(valid_attrs, user.id, accepted_at)
    end

    test "create_accepted_terms/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Legal.create_accepted_terms(%{}, nil, NaiveDateTime.utc_now())
    end

    test "delete_accepted_terms/1 deletes the accepted_terms" do
      accepted_terms = Factory.create_accepted_terms()
      assert {:ok, %AcceptedTerms{}} = Legal.delete_accepted_terms(accepted_terms)
      assert_raise Ecto.NoResultsError, fn -> Legal.get_accepted_terms!(accepted_terms.id) end
    end

    test "change_accepted_terms/1 returns a accepted_terms changeset" do
      accepted_terms = Factory.create_accepted_terms()
      assert %Ecto.Changeset{} = Legal.change_accepted_terms(accepted_terms)
    end

    test "user_has_agreed_to_latest_terms_by/1 returns :ok if user has agreed to latest terms" do
      user = Factory.create_user()
      required_at = ~N[2020-05-08 00:00:00]
      accepted_at = ~N[2020-05-08 01:00:00]

      terms = Factory.create_terms(%{required_at: required_at})

      _accepted_terms =
        Factory.create_accepted_terms(%{
          user_id: user.id,
          terms_id: terms.id,
          accepted_at: accepted_at
        })

      assert Legal.user_has_agreed_to_latest_terms_by(user, ~N[2020-05-08 02:00:00]) == :ok
    end

    test "user_has_agreed_to_latest_terms/1 returns :error tuple if user has agreed to old terms but not agreed to latest" do
      user = Factory.create_user()
      old_required_at = ~N[2020-05-06 00:00:00]
      old_accepted_at = ~N[2020-05-07 00:00:00]
      new_required_at = ~N[2020-05-08 00:00:00]

      old_terms = Factory.create_terms(%{required_at: old_required_at})

      _accepted_old_terms =
        Factory.create_accepted_terms(%{
          user_id: user.id,
          terms_id: old_terms.id,
          accepted_at: old_accepted_at
        })

      %{id: id} = Factory.create_terms(%{required_at: new_required_at})

      assert {:error, {:new_terms, %Terms{id: ^id}}} =
               Legal.user_has_agreed_to_latest_terms_by(user, ~N[2020-05-08 02:00:00])
    end

    test "user_has_agreed_to_latest_terms/1 returns :ok if there are no terms required" do
      user = Factory.create_user()

      assert :ok = Legal.user_has_agreed_to_latest_terms_by(user, ~N[2020-05-08 02:00:00])

      future_required_at = ~N[2021-05-06 00:00:00]

      _terms = Factory.create_terms(%{required_at: future_required_at})
      assert :ok = Legal.user_has_agreed_to_latest_terms_by(user, ~N[2020-05-08 02:00:00])
    end
  end
end
