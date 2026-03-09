defmodule Mix.Tasks.PdfZusammenfuegen.Merge do
  use Mix.Task

  @shortdoc "Fuegt mehrere PDF-Dateien lokal zusammen"

  @moduledoc """
  Fuegt mehrere PDF-Dateien ueber `PdfZusammenfuegen` zusammen.

  ## Beispiel

      mix pdf_zusammenfuegen.merge eingang-1.pdf eingang-2.pdf --output merged.pdf
  """

  @impl Mix.Task
  def run(argv) do
    {opts, input_paths, invalid} =
      OptionParser.parse(argv, strict: [output: :string, help: :boolean], aliases: [o: :output])

    cond do
      opts[:help] ->
        Mix.shell().info(usage())

      invalid != [] ->
        Mix.raise("Unbekannte Optionen: #{format_invalid_options(invalid)}\n\n#{usage()}")

      input_paths == [] ->
        Mix.raise("Bitte gib mindestens eine PDF-Datei an.\n\n#{usage()}")

      is_nil(opts[:output]) ->
        Mix.raise("Bitte gib einen Ausgabepfad mit --output an.\n\n#{usage()}")

      true ->
        case PdfZusammenfuegen.merge_files(input_paths, opts[:output]) do
          {:ok, output_path} ->
            Mix.shell().info("Zusammengefuehrte PDF gespeichert unter: #{output_path}")

          {:error, reason} ->
            Mix.raise(PdfZusammenfuegen.format_error(reason))
        end
    end
  end

  defp format_invalid_options(invalid) do
    invalid
    |> Enum.map(fn {key, _value} -> "--#{key}" end)
    |> Enum.join(", ")
  end

  defp usage do
    """
    Verwendung:
      mix pdf_zusammenfuegen.merge DATEI1.pdf DATEI2.pdf --output merged.pdf

    Optionen:
      --output, -o   Zielpfad fuer die zusammengefuehrte PDF
      --help         Diese Hilfe anzeigen
    """
  end
end
