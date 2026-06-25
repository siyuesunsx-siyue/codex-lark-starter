# Assets

This directory contains visual assets (diagrams, screenshots) for the
repository.

---

## Asset Inventory

| File | Purpose | Format | Source |
|------|---------|--------|--------|
| `architecture.svg` | Full system architecture diagram | SVG | Hand-authored |
| *(planned)* `screenshot-channel.png` | Screenshot of the bot replying in a Feishu channel | PNG | Screenshot |
| *(planned)* `screenshot-config.png` | Screenshot of config.json structure | PNG | Screenshot |
| *(planned)* `screenshot-install.gif` | Animated terminal recording of the install flow | GIF | asciinema / terminalizer |

---

## Guidelines for Adding Assets

- **Prefer SVG** for diagrams.  SVG is text, diffable, and renders at any
  resolution.
- **Keep screenshots under 500 KB.**  Compress PNGs with `pngquant` or
  `oxipng`.
- **Animated GIFs must be under 2 MB.**  Use `gifsicle` for optimization.
- **No personal information** in screenshots (blur or redact names, API
  keys, chat content).
- **Use 2x resolution** for Retina/HiDPI displays (e.g. 1440px wide for a
  720px intended display width).

---

## Diagram Maintenance

The `architecture.svg` diagram is hand-authored.  When the architecture
changes:

1. Update `docs/architecture.md` (the canonical text description).
2. Update `assets/architecture.svg` to match.
3. If the change is significant, increment the version comment in the SVG
   metadata.

Tools that work well for editing SVG diagrams:

- [draw.io](https://app.diagrams.net/) (export as uncompressed SVG)
- [Excalidraw](https://excalidraw.com/)
- Inkscape (native SVG editor)
- Any text editor (SVG is XML)

---

## Placeholder Notes

Images marked as *(planned)* above have not been created yet.  If you add
one, update this file and the asset inventory table.
