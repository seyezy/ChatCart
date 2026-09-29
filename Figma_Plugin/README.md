# ChatCart Figma Generator

This is a local Figma plugin that creates ChatCart as editable Figma objects — not flattened images.

## Install in Figma Desktop

1. Open **Figma Desktop**.
2. Open or create a design file.
3. Go to **Plugins → Development → Import plugin from manifest...**
4. Select this folder's `manifest.json`.
5. Run **Plugins → Development → ChatCart UI Generator**.
6. The plugin creates:
   - `02 — Components`
   - `07–08 — Master Screens`
   - 12 Light Mode master frames
   - 12 Dark Mode master frames
   - editable text, rectangles, icons/symbols, cards, bubbles, navigation and inputs

All generated nodes remain editable in Figma. You can convert repeated generated groups into Figma Components/Variants or extend the plugin further.

## Master frame

393 × 852 px.

## Note

This local plugin uses only Figma's Plugin API and Inter. It does not depend on an external server.

## Firebase extension compatibility

The Flutter/Firebase extension does not modify the visual generator. Running this plugin continues to generate the same editable ChatCart Light/Dark master frames and reusable UI layers. Firebase state (online, typing, read, loading/error, marketplace data) maps onto the existing component states at runtime.
