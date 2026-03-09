# Hex.pm Publishing fuer `pdf_zusammenfuegen`

Dieses Dokument beschreibt die Schritte, um das Paket als echte Hex.pm-Distribution zu veroeffentlichen und den Backlink zu `https://pdfzus.de/` sauber zu platzieren.

## 1. Voraussetzungen

- Elixir und Erlang installiert
- Hex lokal installiert
- ein oeffentliches GitHub-Repository unter der geplanten URL `https://github.com/wsgtcyx/pdf_zusammenfuegen`
- Hex.pm-Account mit verifiziertem Maintainer-Zugang

Falls auf macOS lokale Zertifikate nicht automatisch erkannt werden, setze bei Hex-Kommandos:

```bash
export HEX_CACERTS_PATH=/usr/local/etc/openssl@3/cert.pem
```

## 2. Repository vorbereiten

```bash
cd reference-repos/hex-pm-pdf_zusammenfuegen
git init
git add .
git commit -m "Initial release for Hex.pm"
git remote add origin git@github.com:wsgtcyx/pdf_zusammenfuegen.git
git push -u origin main
```

Wenn du das GitHub-Repository lieber per Weboberflaeche anlegst, reicht es, wenn die finale URL mit `mix.exs` uebereinstimmt.

## 3. Hex einrichten

```bash
HEX_CACERTS_PATH=/usr/local/etc/openssl@3/cert.pem mix local.hex --force
HEX_CACERTS_PATH=/usr/local/etc/openssl@3/cert.pem mix local.rebar --force
```

Danach mit deinem Maintainer-Account anmelden:

```bash
HEX_CACERTS_PATH=/usr/local/etc/openssl@3/cert.pem mix hex.user auth
```

Alternativ per API-Key:

```bash
export HEX_API_KEY=...
```

## 4. Vor dem Release pruefen

```bash
mix format --check-formatted
mix test
mix docs
mix hex.build
HEX_CACERTS_PATH=/usr/local/etc/openssl@3/cert.pem mix hex.publish --dry-run
```

Checkliste:

- `README.md` ist auf Deutsch
- `Homepage` in `package.links` zeigt auf `https://pdfzus.de/`
- `GitHub` in `package.links` zeigt auf das oeffentliche Repo
- `CHANGELOG.md` und `LICENSE` sind im Paket enthalten

## 5. Verifizieren nach dem Dry-Run

Den erzeugten Tarball kopierst du optional in `artifacts/`:

```bash
mkdir -p artifacts
cp pdf_zusammenfuegen-*.tar artifacts/
```

Dann das Paket veroeffentlichen:

```bash
HEX_CACERTS_PATH=/usr/local/etc/openssl@3/cert.pem mix hex.publish
```

## 6. Nach dem Release pruefen

- Hex-Paketseite oeffnen und sicherstellen, dass `Homepage` auf `https://pdfzus.de/` zeigt
- HexDocs pruefen und Link zur Projektseite bestaetigen
- in einem frischen Mix-Projekt testweise installieren:

```bash
mix new /tmp/pdf_zusammenfuegen_smoke
cd /tmp/pdf_zusammenfuegen_smoke
```

`mix.exs` um `{:pdf_zusammenfuegen, "~> 0.1.0"}` erweitern und anschliessend:

```bash
mix deps.get
mix run -e 'PdfZusammenfuegen.merge_to_binary(["/pfad/a.pdf", "/pfad/b.pdf"]) |> IO.inspect()'
```

## 7. Handoff fuer Login

Fuer diese Session ist vorgesehen, dass GitHub-Repo-Erstellung, `git push` und `mix hex.user auth` von dir uebernommen werden, sobald Login oder bestaetigte Credentials benoetigt werden.
