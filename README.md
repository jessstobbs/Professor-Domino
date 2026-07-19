# Professor Domino

A tiny native macOS desktop companion that sends quotes throughout the day.

## Run

```bash
cd /Users/jessica/workspaces/jess/projects/Home-Projects/quote-companion
chmod +x run.sh
./run.sh
```

The companion appears on the desktop and in the menu bar.

## Use

- Hover over Domino to show an immediate quote.
- Drag Domino to move him around the screen.
- Hover over Domino's nose, then click it, to open the quote editor.
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
