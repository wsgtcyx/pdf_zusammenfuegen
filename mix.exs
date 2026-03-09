defmodule PdfZusammenfuegen.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/wsgtcyx/pdf_zusammenfuegen"
  @homepage_url "https://pdfzus.de/"
  @description "PDF-Dateien lokal in Elixir zusammenfuegen, ohne Uploads und mit klarem Dateipfad-API."

  def project do
    [
      app: :pdf_zusammenfuegen,
      version: @version,
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      description: @description,
      package: package(),
      docs: docs(),
      source_url: @source_url,
      homepage_url: @homepage_url,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:merge_pdf, "~> 0.5.2"},
      {:ex_doc, "~> 0.38", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "CHANGELOG.md", "PUBLISHING.de.md"],
      source_url: @source_url,
      homepage_url: @homepage_url
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      maintainers: ["yxchen1994"],
      links: %{
        "Homepage" => @homepage_url,
        "GitHub" => @source_url
      },
      files: [
        ".formatter.exs",
        "CHANGELOG.md",
        "LICENSE",
        "PUBLISHING.de.md",
        "README.md",
        "lib",
        "mix.exs"
      ]
    ]
  end
end
