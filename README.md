# Professor Domino

A tiny desktop companion that sends quotes throughout the day.

Professor Domino now has an Electron version for macOS, Windows, and Linux. The original Swift macOS prototype is still in this repo as `QuoteCompanion.swift`.

## Run the Electron App

```bash
cd /Users/jessica/workspaces/jess/projects/Home-Projects/quote-companion
npm install
npm start
```

## Package Installers

Create a local unpacked app for your current computer:

```bash
npm run pack
```

Create release installers:

```bash
npm run dist:mac
npm run dist:win
npm run dist:linux
```

The packaged apps appear in `dist/`.

For real cross-platform releases, use the included GitHub Actions workflow:

```text
.github/workflows/release.yml
```

On pushes to `main`, it builds test artifacts. To publish a public release, run the workflow manually with a new tag like `v1.0.3`. It builds Android, macOS, Windows, and Linux first, verifies the expected download files exist, and only then creates or updates the latest GitHub release.

## Run the Original Swift Prototype

```bash
cd /Users/jessica/workspaces/jess/projects/Home-Projects/quote-companion
chmod +x run.sh
./run.sh
```

The companion appears on the desktop and in the menu bar. This version is macOS-only.

## Use

- Hover over Domino to show an immediate quote.
- Drag Domino to move him around the screen.
- Hover over Domino's nose, then click it, to open the quote editor.
- Double-click Domino to open the quote editor in the Electron version.
- `Say Something Now` shows an immediate quote.
- `Add Quote` opens the quote editor.
- `Every` changes the quote interval.
- `Edit Quotes` opens the quote editor.
- `Reload Quotes` reads your edited quote list without restarting.

## Quotes

Domino creates and reads this file:

```text
~/Documents/Professor Domino/quotes.json
```

Add quotes using this format:

```json
[
  {
    "text": "Begin anywhere.",
    "author": "John Cage"
  },
  {
    "text": "Small steps still move the whole day.",
    "author": null
  }
]
```

After editing, choose `Reload Quotes` from Domino's menu.
