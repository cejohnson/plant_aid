alias NimbleCSV.RFC4180, as: CSV

[filepath | []] = System.argv()
Path.rootname(filepath)

is_blank_or_null = fn (value) -> is_nil(value) || value == "" || String.downcase(value) == "null" || String.downcase(value) |> String.contains?("unknown") end

[headers | content] = filepath
|> File.read!()
|> CSV.parse_string(skip_headers: false)

content = content
  |> Enum.filter(fn row ->
    # 16, 17, 20-30, 31-42
    !is_blank_or_null.(Enum.at(row, 16))
    || !is_blank_or_null.(Enum.at(row, 17))
    || Enum.any?(31..42, fn index ->
      !is_blank_or_null.(Enum.at(row, index))
    end)
    || Enum.any?(31..42, fn index ->
      !is_blank_or_null.(Enum.at(row, index))
    end)
  end)

Path.rootname(filepath) <> "_genotype_or_any_microsat_fields.csv"
|> File.write(CSV.dump_to_iodata([headers | content]))
