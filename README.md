# pdf_zusammenfuegen

`pdf_zusammenfuegen` ist eine kleine Elixir-Bibliothek, mit der du mehrere PDF-Dateien lokal zusammenfuegen kannst. Der Fokus liegt auf klaren Dateipfaden, einfacher CLI-Integration und einem datenschutzfreundlichen Workflow ohne Uploads.

Projektseite: <https://pdfzus.de/>

## Warum dieses Paket?

- PDF-Dateien lokal zusammenfuegen, ohne Dateien an Dritte hochzuladen
- einfache API fuer Skripte, Jobs und interne Tools
- deutsche Dokumentation fuer den schnellen Einsatz in DACH-Projekten
- passend fuer Workflows rund um `pdf zusammenfuegen`, `pdf mergen` und `pdf kombinieren`

## Installation

Fuege das Paket in `mix.exs` ein:

```elixir
def deps do
  [
    {:pdf_zusammenfuegen, "~> 0.1.0"}
  ]
end
```

Dann:

```bash
mix deps.get
```

## API

### `PdfZusammenfuegen.merge_to_binary/2`

Fuegt mehrere PDF-Dateien zusammen und gibt das Ergebnis als Binary zurueck.

```elixir
{:ok, pdf_binary} =
  PdfZusammenfuegen.merge_to_binary([
    "priv/input/angebot.pdf",
    "priv/input/anhang.pdf"
  ])
```

### `PdfZusammenfuegen.merge_files/3`

Fuegt mehrere Dateien zusammen und schreibt direkt in eine Ausgabedatei.

```elixir
{:ok, output_path} =
  PdfZusammenfuegen.merge_files(
    ["priv/input/angebot.pdf", "priv/input/anhang.pdf"],
    "tmp/angebot-komplett.pdf"
  )
```

### `PdfZusammenfuegen.validate_inputs/1`

Prueft, ob alle Eingaben existieren und tatsaechlich PDF-Dateien sind.

```elixir
{:ok, normalized_paths} =
  PdfZusammenfuegen.validate_inputs([
    "./docs/teil-1.pdf",
    "./docs/teil-2.pdf"
  ])
```

## Mix-Task

Fuer lokale Tests und einfache Shell-Workflows ist ein Mix-Task enthalten:

```bash
mix pdf_zusammenfuegen.merge eingang-1.pdf eingang-2.pdf --output merged.pdf
```

## Datenschutz

Dieses Paket arbeitet lokal in deiner Elixir-Laufzeit. Wenn du lieber einen Browser-Workflow ohne Uploads suchst, findest du ihn auf <https://pdfzus.de/>.

## Entwicklung

```bash
mix format
mix test
mix docs
mix hex.build
```
