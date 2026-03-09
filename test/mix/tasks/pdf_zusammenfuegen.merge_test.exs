defmodule Mix.Tasks.PdfZusammenfuegen.MergeTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias PdfZusammenfuegen.TestSupport.PdfFixture

  setup context do
    tmp_dir = PdfFixture.tmp_dir(context.test)

    on_exit(fn ->
      File.rm_rf!(tmp_dir)
    end)

    {:ok, tmp_dir: tmp_dir}
  end

  test "Mix task fuehrt PDFs zusammen und schreibt die Ausgabe", %{tmp_dir: tmp_dir} do
    first_pdf =
      PdfFixture.write_single_page_pdf(Path.join(tmp_dir, "eins.pdf"), text: "ERSTE-QUELLE")

    second_pdf =
      PdfFixture.write_single_page_pdf(Path.join(tmp_dir, "zwei.pdf"), text: "ZWEITE-QUELLE")

    output_path = Path.join(tmp_dir, "merged.pdf")

    output =
      capture_io(fn ->
        Mix.Tasks.PdfZusammenfuegen.Merge.run([first_pdf, second_pdf, "--output", output_path])
      end)

    Mix.Task.reenable("pdf_zusammenfuegen.merge")

    assert output =~ "Zusammengefuehrte PDF gespeichert unter:"
    assert File.exists?(output_path)
    assert PdfFixture.page_count(output_path) == 2
  end

  test "Mix task meldet fehlende --output Option lesbar", %{tmp_dir: tmp_dir} do
    input_path =
      PdfFixture.write_single_page_pdf(Path.join(tmp_dir, "eins.pdf"), text: "ERSTE-QUELLE")

    assert_raise Mix.Error, ~r/Bitte gib einen Ausgabepfad mit --output an./, fn ->
      capture_io(fn ->
        Mix.Tasks.PdfZusammenfuegen.Merge.run([input_path])
      end)
    end

    Mix.Task.reenable("pdf_zusammenfuegen.merge")
  end
end
