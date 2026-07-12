import QtQuick

// Lacuna design-language token registry (see docs/lacuna-design-system).
//
// This is the component-level vocabulary. Each token family resolves either
// here or in the module noted, per the design language:
//   recess*            interaction depth (alpha of the state color over a
//                      surface, never a new hue) — defined below
//   space* / text*     spacing and type scale (02-geometry / 04-typography)
//   curveKappa         seam / molding-connector geometry — LacunaGeometry.qml
//   field/void/plate/ink/whisper/soft/seam/accent/danger
//                      theme-derived color roles — Theme.qml / DesignTokens.qml
//   reveal / threshold disclosure motion and its content-fade gate
//                      — MotionTokens.qml (the named reveal scale)
QtObject {
  id: root

  readonly property string monoFont: "Hack Nerd Font Propo"
  readonly property string displayFont: "Tektur"

  // Motion durations live in MotionTokens (the named reveal scale,
  // 03-motion.md), not here.

  // Interaction depth — the "recess" family (05-components.md). Pressing into
  // a surface is rendered as a sinking-in: an alpha of the state color, not a
  // tint or glow. These are the canonical lacuna-style values.
  readonly property real recessRest: 0.0
  readonly property real recessHover: 0.06
  readonly property real recessPress: 0.11

  readonly property int spaceTiny: 2
  readonly property int spaceSmall: 4
  readonly property int spaceNormal: 8
  readonly property int spaceLarge: 10
  readonly property int spaceXLarge: 14

  readonly property int textHint: 9
  readonly property int textSmall: 10
  readonly property int textNormal: 12
  readonly property int textPrimary: 13
  readonly property int textTitle: 16
  readonly property int textIcon: 15
  readonly property int textGlyph: 20

  readonly property real trackingTitle: 2.0
  readonly property real trackingTitleCompact: 1.4
  readonly property real trackingMenuItem: 0.9
  readonly property real trackingMenuItemCompact: 0.6
  readonly property real trackingBody: 0.0
  readonly property real trackingSection: 0.0

  readonly property int controlSmall: 30
  readonly property int controlNormal: 34
}
