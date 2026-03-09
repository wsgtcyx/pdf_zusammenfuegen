defmodule PdfZusammenfuegen do
  @moduledoc """
  Ein kleines Elixir-Wrapper-Paket zum lokalen Zusammenfuegen von PDF-Dateien.

  Der Fokus liegt auf einem klaren Dateipfad-API fuer Automatisierungen,
  Build-Pipelines und Backoffice-Workflows. Die Projekt-Homepage ist
  <https://pdfzus.de/>.
  """

  @typedoc "Eine normalisierte Liste absoluter PDF-Dateipfade."
  @type validated_paths :: [String.t()]

  @typedoc "Bekannte Fehlerformen fuer Validierung, Merge und Dateiausgabe."
  @type error_reason ::
          {:invalid_input, String.t()}
          | {:missing_file, String.t()}
          | {:not_a_file, String.t()}
          | {:invalid_pdf, String.t()}
          | {:merge_failed, term()}
          | {:write_failed, String.t(), File.posix()}

  @doc """
  Validiert eine Liste von Eingabedateien.

  Jede Datei muss existieren, eine regulaere Datei sein und mit dem PDF-Header
  `%PDF-` beginnen.
  """
  @spec validate_inputs([String.t()]) :: {:ok, validated_paths()} | {:error, error_reason()}
  def validate_inputs(input_paths) when is_list(input_paths) do
    cond do
      input_paths == [] ->
        {:error, {:invalid_input, "Mindestens eine PDF-Datei ist erforderlich."}}

      true ->
        input_paths
        |> Enum.reduce_while({:ok, []}, fn path, {:ok, acc} ->
          case normalize_input_path(path) do
            {:ok, normalized_path} -> {:cont, {:ok, [normalized_path | acc]}}
            {:error, _} = error -> {:halt, error}
          end
        end)
        |> case do
          {:ok, normalized_paths} -> {:ok, Enum.reverse(normalized_paths)}
          {:error, _} = error -> error
        end
    end
  end

  def validate_inputs(_input_paths) do
    {:error, {:invalid_input, "Die Eingabe muss eine Liste von Dateipfaden sein."}}
  end

  @doc """
  Fuegt mehrere PDF-Dateien zusammen und gibt das Ergebnis als Binary zurueck.

  Standardmaessig wird das Ergebnis lokal und ohne Uploads verarbeitet. Fuer
  die Projektseite und den Browser-Workflow siehe <https://pdfzus.de/>.
  """
  @spec merge_to_binary([String.t()], keyword()) :: {:ok, binary()} | {:error, error_reason()}
  def merge_to_binary(input_paths, opts \\ []) do
    merge_pdf_module = Keyword.get(opts, :merge_pdf_module, MergePdf)

    with {:ok, validated_paths} <- validate_inputs(input_paths),
         {:ok, merged_binary} <- merge_with_module(merge_pdf_module, validated_paths) do
      {:ok, merged_binary}
    end
  end

  @doc """
  Fuegt mehrere PDF-Dateien zusammen und schreibt das Ergebnis auf die Platte.

  Unterstuetzte Optionen:

    * `:mkdir_p?` - legt das Ausgabeverzeichnis an, falls es noch nicht existiert.
      Standardwert: `true`
  """
  @spec merge_files([String.t()], String.t(), keyword()) ::
          {:ok, String.t()} | {:error, error_reason()}
  def merge_files(input_paths, output_path, opts \\ [])

  def merge_files(input_paths, output_path, opts) when is_binary(output_path) do
    expanded_output_path = Path.expand(output_path)
    mkdir_p? = Keyword.get(opts, :mkdir_p?, true)

    with :ok <- ensure_output_path(expanded_output_path, mkdir_p?),
         {:ok, merged_binary} <- merge_to_binary(input_paths, opts),
         :ok <- write_output(expanded_output_path, merged_binary) do
      {:ok, expanded_output_path}
    end
  end

  def merge_files(_input_paths, _output_path, _opts) do
    {:error, {:invalid_input, "Der Ausgabepfad muss ein nicht-leerer String sein."}}
  end

  @doc """
  Formatiert einen Rueckgabefehler als lesbare deutsche Meldung.
  """
  @spec format_error(error_reason()) :: String.t()
  def format_error({:invalid_input, message}), do: message
  def format_error({:missing_file, path}), do: "Datei nicht gefunden: #{path}"
  def format_error({:not_a_file, path}), do: "Kein regulaerer Dateipfad: #{path}"
  def format_error({:invalid_pdf, path}), do: "Datei ist kein gueltiges PDF: #{path}"

  def format_error({:merge_failed, reason}) do
    "PDFs konnten nicht zusammengefuegt werden: #{inspect(reason)}"
  end

  def format_error({:write_failed, path, reason}) do
    "Ausgabedatei konnte nicht geschrieben werden (#{reason}): #{path}"
  end

  defp normalize_input_path(path) when is_binary(path) do
    trimmed_path = String.trim(path)
    normalized_path = Path.expand(trimmed_path)

    cond do
      trimmed_path == "" ->
        {:error, {:invalid_input, "Leere Dateipfade sind nicht erlaubt."}}

      not File.exists?(normalized_path) ->
        {:error, {:missing_file, normalized_path}}

      not regular_file?(normalized_path) ->
        {:error, {:not_a_file, normalized_path}}

      not pdf_file?(normalized_path) ->
        {:error, {:invalid_pdf, normalized_path}}

      true ->
        {:ok, normalized_path}
    end
  end

  defp normalize_input_path(_path) do
    {:error, {:invalid_input, "Alle Eingabepfade muessen Strings sein."}}
  end

  defp regular_file?(path) do
    case File.stat(path) do
      {:ok, %File.Stat{type: :regular}} -> true
      _ -> false
    end
  end

  defp pdf_file?(path) do
    with {:ok, device} <- File.open(path, [:read, :binary]),
         header <- IO.binread(device, 5),
         :ok <- File.close(device) do
      header == "%PDF-"
    else
      _ -> false
    end
  end

  defp merge_with_module(merge_pdf_module, validated_paths) do
    case merge_pdf_module.merge_paths(validated_paths) do
      {:ok, merged_binary} when is_binary(merged_binary) ->
        {:ok, merged_binary}

      merged_binary when is_binary(merged_binary) ->
        {:ok, merged_binary}

      {:error, reason} ->
        {:error, {:merge_failed, reason}}

      other ->
        {:error, {:merge_failed, other}}
    end
  end

  defp ensure_output_path(output_path, mkdir_p?) do
    if String.trim(output_path) == "" do
      {:error, {:invalid_input, "Der Ausgabepfad darf nicht leer sein."}}
    else
      output_dir = Path.dirname(output_path)

      case mkdir_p? do
        true -> File.mkdir_p(output_dir)
        false -> :ok
      end
    end
  end

  defp write_output(output_path, merged_binary) do
    case File.write(output_path, merged_binary) do
      :ok -> :ok
      {:error, reason} -> {:error, {:write_failed, output_path, reason}}
    end
  end
end
