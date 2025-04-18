defmodule PlantAid.ObjectStorage do
  @moduledoc """
  Dependency-free S3-compatible Form Upload using HTTP POST sigv4

  https://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-post-example.html

  Copied from https://gist.github.com/chrismccord/37862f1f8b1f5148644b75d20d1cb073 and tweaked
  """

  def get_upload_meta(opts) do
    object_storage = Application.get_env(:plant_aid, PlantAid.ObjectStorage)

    config = %{
      region: object_storage[:region],
      access_key_id: object_storage[:access_key_id],
      secret_access_key: object_storage[:secret_access_key]
    }

    {:ok, fields} =
      sign_form_upload(config, object_storage[:bucket],
        key: opts[:key],
        content_type: opts[:content_type],
        max_file_size: opts[:max_file_size],
        expires_in: opts[:expires_in]
      )

    %{
      uploader: "S3",
      key: opts[:key],
      url: base_url(),
      fields: fields
    }
  end

  def get_url(key) do
    Path.join(base_url(), key)
  end

  defp base_url() do
    object_storage = Application.get_env(:plant_aid, PlantAid.ObjectStorage)
    "https://#{object_storage[:bucket]}.#{object_storage[:region]}.#{object_storage[:domain]}"
  end

  def delete_objects([]) do
  end

  def delete_objects(urls) do
    object_storage = Application.get_env(:plant_aid, PlantAid.ObjectStorage)

    objects =
      urls
      |> Enum.filter(&is_binary/1)
      |> Enum.map(fn url ->
        uri = URI.new!(url)

        uri.path
        |> String.slice(1..-1//1)
      end)

    if length(objects) > 0 do
      ExAws.S3.delete_multiple_objects(object_storage[:bucket], objects)
      |> ExAws.request!(
        host: object_storage[:region] <> "." <> object_storage[:domain],
        access_key_id: object_storage[:access_key_id],
        secret_access_key: object_storage[:secret_access_key]
      )
    end
  end

  @doc """
  Signs a form upload.

  The configuration is a map which must contain the following keys:

    * `:region` - The AWS region, such as "us-east-1"
    * `:access_key_id` - The AWS access key id
    * `:secret_access_key` - The AWS secret access key


  Returns a map of form fields to be used on the client via the JavaScript `FormData` API.

  ## Options

    * `:key` - The required key of the object to be uploaded.
    * `:max_file_size` - The required maximum allowed file size in bytes.
    * `:content_type` - The required MIME type of the file to be uploaded.
    * `:expires_in` - The required expiration time in milliseconds from now
      before the signed upload expires.

  ## Examples

      config = %{
        region: "us-east-1",
        access_key_id: System.fetch_env!("AWS_ACCESS_KEY_ID"),
        secret_access_key: System.fetch_env!("AWS_SECRET_ACCESS_KEY")
      }

      {:ok, fields} =
        SimpleS3Upload.sign_form_upload(config, "my-bucket",
          key: "public/my-file-name",
          content_type: "image/png",
          max_file_size: 10_000,
          expires_in: :timer.hours(1)
        )

  """
  def sign_form_upload(config, bucket, opts) do
    key = Keyword.fetch!(opts, :key)
    max_file_size = Keyword.fetch!(opts, :max_file_size)
    content_type = Keyword.fetch!(opts, :content_type)
    expires_in = Keyword.fetch!(opts, :expires_in)

    expires_at = DateTime.add(DateTime.utc_now(), expires_in, :millisecond)
    amz_date = amz_date(expires_at)
    credential = credential(config, expires_at)

    encoded_policy =
      Base.encode64("""
      {
        "expiration": "#{DateTime.to_iso8601(expires_at)}",
        "conditions": [
          {"bucket":  "#{bucket}"},
          ["eq", "$key", "#{key}"],
          {"acl": "public-read"},
          ["eq", "$Content-Type", "#{content_type}"],
          ["content-length-range", 0, #{max_file_size}],
          {"x-amz-server-side-encryption": "AES256"},
          {"x-amz-credential": "#{credential}"},
          {"x-amz-algorithm": "AWS4-HMAC-SHA256"},
          {"x-amz-date": "#{amz_date}"}
        ]
      }
      """)

    fields = %{
      "key" => key,
      "acl" => "public-read",
      "content-type" => content_type,
      "x-amz-server-side-encryption" => "AES256",
      "x-amz-credential" => credential,
      "x-amz-algorithm" => "AWS4-HMAC-SHA256",
      "x-amz-date" => amz_date,
      "policy" => encoded_policy,
      "x-amz-signature" => signature(config, expires_at, encoded_policy)
    }

    {:ok, fields}
  end

  defp amz_date(time) do
    time
    |> NaiveDateTime.to_iso8601()
    |> String.split(".")
    |> List.first()
    |> String.replace("-", "")
    |> String.replace(":", "")
    |> Kernel.<>("Z")
  end

  defp credential(%{} = config, %DateTime{} = expires_at) do
    "#{config.access_key_id}/#{short_date(expires_at)}/#{config.region}/s3/aws4_request"
  end

  defp signature(config, %DateTime{} = expires_at, encoded_policy) do
    config
    |> signing_key(expires_at, "s3")
    |> sha256(encoded_policy)
    |> Base.encode16(case: :lower)
  end

  defp signing_key(%{} = config, %DateTime{} = expires_at, service) when service in ["s3"] do
    amz_date = short_date(expires_at)
    %{secret_access_key: secret, region: region} = config

    ("AWS4" <> secret)
    |> sha256(amz_date)
    |> sha256(region)
    |> sha256(service)
    |> sha256("aws4_request")
  end

  defp short_date(%DateTime{} = expires_at) do
    expires_at
    |> amz_date()
    |> String.slice(0..7)
  end

  defp sha256(secret, msg), do: :crypto.mac(:hmac, :sha256, secret, msg)
end
