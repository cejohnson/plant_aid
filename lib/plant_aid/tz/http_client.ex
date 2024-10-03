defmodule PlantAid.Tz.HTTPClient do
  @behaviour Tz.HTTP.HTTPClient

  alias Tz.HTTP.HTTPResponse
  alias MyApp.MyFinch

  @impl Tz.HTTP.HTTPClient
  def request(hostname, path) do
    {:ok, response} =
      Finch.build(:get, "https://" <> Path.join(hostname, path))
      |> Finch.request(MyFinch)

    %HTTPResponse{
      status_code: response.status,
      body: response.body
    }
  end
end
