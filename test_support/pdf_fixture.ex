defmodule PdfZusammenfuegen.TestSupport.PdfFixture do
  @moduledoc false

  def tmp_dir(test_name) do
    dir =
      Path.join(
        System.tmp_dir!(),
        "pdf_zusammenfuegen_tests/#{System.unique_integer([:positive])}-#{test_name}"
      )

    File.mkdir_p!(dir)
    dir
  end

  def write_single_page_pdf(path, opts \\ []) do
    width = Keyword.get(opts, :width, 595)
    height = Keyword.get(opts, :height, 842)
    text = Keyword.get(opts, :text, Path.basename(path))

    content_stream = "BT /F1 18 Tf 72 #{height - 72} Td (#{escape_pdf_text(text)}) Tj ET"

    objects = [
      "1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n",
      "2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n",
      "3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 #{width} #{height}] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>\nendobj\n",
      "4 0 obj\n<< /Length #{byte_size(content_stream)} >>\nstream\n#{content_stream}\nendstream\nendobj\n",
      "5 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n"
    ]

    pdf_binary = build_pdf(objects)
    File.write!(path, pdf_binary)
    path
  end

  def write_invalid_file(path, content \\ "kein pdf") do
    File.write!(path, content)
    path
  end

  def page_count(pdf_binary_or_path) do
    pdf_binary_or_path
    |> read_binary()
    |> count_values_after("/Count ")
    |> Enum.max(fn -> 0 end)
  end

  def token_positions(pdf_binary_or_path, tokens) do
    binary = read_binary(pdf_binary_or_path)

    Enum.map(tokens, fn token ->
      case :binary.match(binary, token) do
        {position, _length} -> {token, position}
        :nomatch -> {token, nil}
      end
    end)
  end

  defp count_values_after(binary, marker) do
    do_count_values_after(binary, marker, 0, [])
    |> Enum.reverse()
  end

  defp do_count_values_after(binary, marker, offset, acc) do
    case :binary.match(binary, marker, scope: {offset, byte_size(binary) - offset}) do
      {position, length} ->
        value_offset = position + length
        {value, next_offset} = parse_decimal(binary, value_offset)
        do_count_values_after(binary, marker, next_offset, [value | acc])

      :nomatch ->
        acc
    end
  end

  defp parse_decimal(binary, offset) do
    digits =
      Stream.unfold(offset, fn current_offset ->
        if current_offset < byte_size(binary) do
          <<byte>> = binary_part(binary, current_offset, 1)

          if byte in ?0..?9 do
            {byte, current_offset + 1}
          end
        end
      end)
      |> Enum.to_list()

    parsed_value =
      digits
      |> List.to_string()
      |> case do
        "" -> 0
        value -> String.to_integer(value)
      end

    {parsed_value, offset + max(length(digits), 1)}
  end

  defp read_binary(path) when is_binary(path) do
    if File.exists?(path), do: File.read!(path), else: path
  end

  defp build_pdf(objects) do
    header = "%PDF-1.4\n"

    {body, offsets, _cursor} =
      Enum.reduce(objects, {"", [], byte_size(header)}, fn object, {body, offsets, cursor} ->
        {body <> object, offsets ++ [cursor], cursor + byte_size(object)}
      end)

    xref_start = byte_size(header) + byte_size(body)

    xref_entries =
      ["0000000000 65535 f \n" | Enum.map(offsets, &pad_offset/1)]
      |> Enum.join()

    trailer = """
    xref
    0 #{length(objects) + 1}
    #{xref_entries}trailer
    << /Size #{length(objects) + 1} /Root 1 0 R >>
    startxref
    #{xref_start}
    %%EOF
    """

    header <> body <> trailer
  end

  defp pad_offset(offset) do
    "#{offset |> Integer.to_string() |> String.pad_leading(10, "0")} 00000 n \n"
  end

  defp escape_pdf_text(text) do
    text
    |> String.replace("\\", "\\\\")
    |> String.replace("(", "\\(")
    |> String.replace(")", "\\)")
  end
end
