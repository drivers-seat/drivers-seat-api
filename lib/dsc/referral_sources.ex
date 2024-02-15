defmodule DriversSeatCoop.ReferralSources do
  import Ecto.Query, warn: false
  alias DriversSeatCoop.ReferralSource
  alias DriversSeatCoop.Repo

  def get_referral_source(referral_code) do
    from(rs in ReferralSource,
      where: rs.referral_code == ^referral_code
    )
    |> Repo.one()
  end

  def list_referral_sources(user_id) do
    from(rs in ReferralSource,
      where: rs.user_id == ^user_id,
      where: rs.is_active
    )
    |> Repo.all()
  end

  def create_or_generate_referral_source(referral_type, user_id \\ nil) do
    qry =
      from(rs in ReferralSource,
        where: rs.referral_type == ^referral_type
      )

    qry =
      case user_id do
        nil ->
          from(rs in qry,
            where: is_nil(rs.user_id)
          )

        user_id ->
          from(rs in qry,
            where: rs.user_id == ^user_id
          )
      end

    case Repo.one(qry) do
      nil ->
        generate_referral_source(referral_type, user_id)

      source ->
        {:ok, source}
    end
  end

  def create_referral_source(attrs) do
    %ReferralSource{}
    |> ReferralSource.changeset(attrs)
    |> Repo.insert()
  end

  defp generate_referral_source(referral_type, user_id) do
    create_referral_source(%{
      referral_type: referral_type,
      user_id: user_id,
      referral_code: generate_referral_code(4)
    })
    |> case do
      # There's a chance the random code could have already been used.
      # Filter for this condition and retry with a different code.
      {:error,
       %Ecto.Changeset{
         errors: [
           referral_code: {
             [constraint: :unique, constraint_name: "referral_sources_index_code"]
           }
         ]
       }} ->
        generate_referral_source(referral_type, user_id)

      result ->
        result
    end
  end

  defp generate_referral_code(length) do
    for _ <- 1..length, into: "", do: <<Enum.random(Enum.concat(?A..?Z, ?0..?9))>>
  end
end
