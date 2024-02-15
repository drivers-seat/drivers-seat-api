defmodule DriversSeatCoop.B2 do
  @b2_max_presigned_url_duration 604_800

  defp get_config do
    Application.get_env(:dsc, DriversSeatCoop.B2)
  end

  defp get_auth do
    if has_config?() do
      config = get_config()
      {:ok, auth} = B2Client.backend().authenticate(config[:key_id], config[:application_key])
      {:ok, bucket} = B2Client.backend().get_bucket(auth, config[:bucket])
      {:ok, auth, bucket}
    else
      {:error, :b2_not_configured}
    end
  end

  def has_config? do
    not is_nil(get_config())
  end

  def upload_file(contents, path) do
    with {:ok, auth, bucket} <- get_auth() do
      B2Client.backend().upload(auth, bucket, contents, path)
    end
  end

  def download_file(path) do
    with {:ok, auth, bucket} <- get_auth() do
      {:ok, contents} = B2Client.backend().download(auth, bucket, path)
      contents
    end
  end

  def delete_file(path) do
    with {:ok, auth, bucket} <- get_auth() do
      B2Client.backend().delete(auth, bucket, path)
    end
  end

  def get_presigned_download_url(path, duration_seconds \\ @b2_max_presigned_url_duration) do
    with {:ok, auth, bucket} <- get_auth() do
      url = "#{auth.api_url}/b2api/v2/b2_get_download_authorization"

      headers = [
        {"Authorization", auth.authorization_token}
      ]

      body = %{
        bucketId: bucket.bucket_id,
        fileNamePrefix: path
      }

      body =
        if is_nil(duration_seconds),
          do: body,
          else: Map.put(body, :validDurationInSeconds, duration_seconds)

      with {:ok, body} <- Jason.encode(body),
           {:ok, 200, _, client} <- :hackney.request(:post, url, headers, body),
           {:ok, response} <- :hackney.body(client),
           {:ok, response} <- Jason.decode(response) do
        "#{auth.download_url}/file/#{bucket.bucket_name}/#{path}?Authorization=#{Map.get(response, "authorizationToken")}"
      end
    end
  end
end
