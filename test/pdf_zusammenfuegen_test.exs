defmodule PdfZusammenfuegenTest do
  use ExUnit.Case, async: true

  alias PdfZusammenfuegen.TestSupport.PdfFixture

  setup context do
    tmp_dir = PdfFixture.tmp_dir(context.test)

    on_exit(fn ->
      File.rm_rf!(tmp_dir)
    end)

    {:ok, tmp_dir: tmp_dir}
  end

  test "merge_to_binary fuehrt zwei PDF-Dateien zusammen", %{tmp_dir: tmp_dir} do
    first_pdf =
      PdfFixture.write_single_page_pdf(Path.join(tmp_dir, "eins.pdf"), text: "ERSTE-QUELLE")

    second_pdf =
      PdfFixture.write_single_page_pdf(Path.join(tmp_dir, "zwei.pdf"), text: "ZWEITE-QUELLE")

    assert {:ok, merged_binary} = PdfZusammenfuegen.merge_to_binary([first_pdf, second_pdf])
    assert PdfFixture.page_count(merged_binary) == 2
  end

  test "die Reihenfolge der Eingabedateien bleibt erhalten", %{tmp_dir: tmp_dir} do
    portrait_pdf =
      PdfFixture.write_single_page_pdf(
        Path.join(tmp_dir, "portrait.pdf"),
        text: "ERSTE-QUELLE",
        width: 595,
        height: 842
      )

    landscape_pdf =
      PdfFixture.write_single_page_pdf(
        Path.join(tmp_dir, "landscape.pdf"),
        text: "ZWEITE-QUELLE",
        width: 842,
        height: 595
      )

    assert {:ok, merged_binary} = PdfZusammenfuegen.merge_to_binary([portrait_pdf, landscape_pdf])

    positions =
      PdfFixture.token_positions(merged_binary, ["ERSTE-QUELLE", "ZWEITE-QUELLE"])

    assert [{"ERSTE-QUELLE", first_position}, {"ZWEITE-QUELLE", second_position}] = positions
    assert is_integer(first_position)
    assert is_integer(second_position)
    assert first_position < second_position
  end

  test "leere Eingabeliste liefert einen lesbaren Fehler" do
    assert {:error, {:invalid_input, "Mindestens eine PDF-Datei ist erforderlich."}} =
             PdfZusammenfuegen.merge_to_binary([])
  end

  test "ungueltige oder fehlende Dateien werden erkannt", %{tmp_dir: tmp_dir} do
    missing_pdf = Path.join(tmp_dir, "fehlt.pdf")
    invalid_pdf = PdfFixture.write_invalid_file(Path.join(tmp_dir, "not-a-pdf.txt"))

    assert {:error, {:missing_file, ^missing_pdf}} =
             PdfZusammenfuegen.merge_to_binary([missing_pdf])

    assert {:error, {:invalid_pdf, ^invalid_pdf}} =
             PdfZusammenfuegen.merge_to_binary([invalid_pdf])
  end

  test "merge_files schreibt eine gueltige PDF-Datei", %{tmp_dir: tmp_dir} do
    first_pdf =
      PdfFixture.write_single_page_pdf(Path.join(tmp_dir, "eins.pdf"), text: "ERSTE-QUELLE")

    second_pdf =
      PdfFixture.write_single_page_pdf(Path.join(tmp_dir, "zwei.pdf"), text: "ZWEITE-QUELLE")

    output_path = Path.join([tmp_dir, "nested", "merged.pdf"])

    assert {:ok, written_path} =
             PdfZusammenfuegen.merge_files([first_pdf, second_pdf], output_path)

    assert written_path == Path.expand(output_path)
    assert File.exists?(written_path)
    assert PdfFixture.page_count(written_path) == 2
    assert String.starts_with?(File.read!(written_path), "%PDF-")
  end
end
