# Lacuna Components

Plugin-local QML primitives used by the Lacuna menu. Import them with a
relative plugin path such as `import "../components"`; do not import from the
repository root or rely on `PWD`.

Stable primitives:

- `LacunaRect`: animated transparent `Rectangle` base.
- `LacunaText`: text element with Lacuna defaults and color animation.
- `LacunaIconButton`: icon/text button with hover and secondary-click signals.
- `LacunaStateLayer`: pointer, wheel, hover, and press state layer.
- `LacunaTokens`: shared animation, spacing, sizing, and font tokens.

Animation helpers:

- `LacunaAnim`: standard number animation timing.
- `LacunaColorAnim`: standard color animation timing.

Icon policy:

- Use Tabler filled SVGs for dense topbar status icons when a matching icon
  exists.
- Store Tabler files under each plugin's `assets/tabler/` directory.
- Normalize Tabler SVGs from `fill="currentColor"` or
  `stroke="currentColor"` to `#ffffff` so Qt's SVG loader renders them
  consistently.
- Tint SVGs in QML with `QtQuick.Effects.MultiEffect` and the injected Omarchy
  color (`bar.foreground`, status color, or Lacuna theme token).
- Use a branded SVG only when Tabler does not provide the brand mark.
