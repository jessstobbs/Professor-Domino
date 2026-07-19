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

- Click Domino to show an immediate quote.
- `Say Something Now` shows an immediate quote.
- `Add Quote` opens your editable quotes document.
- `Every` changes the quote interval.
- `Edit Quotes` opens your editable quotes document.
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
