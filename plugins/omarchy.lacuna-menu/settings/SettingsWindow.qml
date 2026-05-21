import QtQuick
import QtQuick.Shapes
import "../components"
import "../services"

Item {
  id: root

  signal activated(var entry)
  signal closeRequested()

  required property var registry
  property bool compact: false
  property bool open: false
  property string currentSection: "overview"
  property string version: ""
  property string themeTitle: ""
  property color foreground: "#d8dee9"
  property color background: "#101315"
  property color accent: "#88c0d0"
  property color shellAccent: "#88c0d0"
  property color sessionAccent: "#ebcb8b"
  property color dangerAccent: "#bf616a"
  property color navAccent: "#d8dee9"
  property color muted: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.48)
  property string bodyFontFamily: "JetBrains Mono"
  property string itemFontFamily: itemFont.name !== "" ? itemFont.name : "Tektur"
  property var designTokens: fallbackDesignTokens
  property bool drawBackground: true
  readonly property int panelRadius: Math.max(designTokens.radius, compact ? 10 : 14)
  readonly property real curveKappa: 0.5522847498

  function sections() {
    return [
      { id: "overview", icon: "apps", label: "Overview", hint: "Current Lacuna state" },
      { id: "appearance", icon: "palette", label: "Appearance", hint: "Style, colors, theme shortcuts" },
      { id: "layout", icon: "density-normal", label: "Layout", hint: "Sidebar and density behavior" },
      { id: "preferred-apps", icon: "preferred-apps", label: "Preferred Apps", hint: "Role-based app launch targets" },
      { id: "desktop-clock", icon: "clock", label: "Desktop Clock", hint: "Desktop layer clock placement" },
      { id: "runtime", icon: "settings", label: "Runtime", hint: "Diagnostics and maintenance" },
      { id: "about", icon: "lacuna", label: "About", hint: "Plugin metadata" }
    ]
  }

  function sectionMeta(section) {
    var all = sections()
    for (var i = 0; i < all.length; i++) {
      if (all[i].id === section) return all[i]
    }
    return all[0]
  }

  function toneAccent(tone) {
    if (tone === "lacuna") return root.accent
    if (tone === "shell") return root.shellAccent
    if (tone === "session") return root.sessionAccent
    if (tone === "danger") return root.dangerAccent
    return root.navAccent
  }

  function section(label, note, tone) {
    return {
      kind: "section",
      label: label,
      note: note || "",
      tone: tone || "lacuna"
    }
  }

  function row(icon, label, hint, value, tone, action, control, checked, options, optionValue, actionPrefix, sectionId) {
    return {
      kind: "row",
      icon: icon,
      label: label,
      hint: hint || "",
      value: value || "",
      tone: tone || "lacuna",
      action: action || "",
      control: control || "nav",
      checked: checked === true,
      options: options || [],
      optionValue: optionValue || "",
      optionActionPrefix: actionPrefix || "",
      settingsSection: sectionId || "",
      view: "",
      command: ""
    }
  }

  function commandRow(icon, label, hint, command, tone) {
    var item = row(icon, label, hint, "Open", tone || "shell", "", "button")
    item.command = command || ""
    return item
  }

  function colorProfileName() {
    return root.registry.colorProfile === "colorful" ? "Colorful" : "Semantic"
  }

  function frameModeName() {
    return root.registry.frameMode === "fullframe" ? "On" : "Off"
  }

  function sidebarModeName() {
    return root.registry.sidebarExclusive ? "Overlay" : "Docked"
  }

  function sidebarShapeName() {
    return root.registry.sidebarCollapsed ? "Icon Rail" : "Full"
  }

  function densityName() {
    return root.registry.barSizeMode === "compact" ? "Compact" : "Full"
  }

  function barSizeModeName() {
    return root.registry.barSizeModeName ? root.registry.barSizeModeName() : "Full"
  }

  function barSizeModeHint() {
    return root.registry.barSizeModeHint ? root.registry.barSizeModeHint() : "Control topbar, sidebar, and rail size together"
  }

  function clockAnchorName() {
    return root.registry.desktopClockAnchor + "  x " + root.registry.desktopClockOffsetX + "  y " + root.registry.desktopClockOffsetY
  }

  function clockScaleName() {
    return Math.round(root.registry.desktopClockScale * 100) + "%"
  }

  function preferredSummary() {
    return root.registry.preferredAppHint("files") + " / " + root.registry.preferredAppHint("editor")
  }

  function navRow(icon, label, hint, sectionId, tone, value) {
    return row(icon, label, hint, value || "", tone || "lacuna", "", "nav", false, [], "", "", sectionId)
  }

  function itemsFor(sectionId) {
    if (sectionId === "overview") {
      return [
        section("Status", "Fast links into each settings area.", "lacuna"),
        navRow("palette", "Appearance", root.registry.designStyleHint(), "appearance", "lacuna", root.registry.designStyleName()),
        navRow(root.registry.compact ? "density-compact" : "density-normal", "Layout", sidebarModeName() + " / " + sidebarShapeName(), "layout", "lacuna", densityName()),
        navRow("preferred-apps", "Preferred Apps", preferredSummary(), "preferred-apps", "lacuna", "Edit"),
        navRow("clock", "Desktop Clock", clockAnchorName(), "desktop-clock", "lacuna", root.registry.desktopClockEnabled ? "On" : "Off"),
        navRow("settings", "Runtime", "Shell commands, logs, and diagnostics", "runtime", "shell", "Tools"),
        navRow("lacuna", "About", root.version !== "" ? root.version : "Lacuna plugin", "about", "lacuna", "Info")
      ]
    }

    if (sectionId === "appearance") {
      return [
        section("Design", "Panel and sidebar visual treatment.", "lacuna"),
        row("palette", "Design Style", root.registry.designStyleHint(), "", "lacuna", "", "segments", false, [
          { value: "lacuna", label: "Lacuna" },
          { value: "omarchy", label: "Omarchy" },
          { value: "material", label: "Material" }
        ], root.registry.designStyle, "set-design-style-"),
        row("color-swatch", "Color Profile", root.registry.colorProfile === "colorful" ? "Use theme colors across Lacuna surfaces" : "Use semantic accents with restrained color", colorProfileName(), "lacuna", "toggle-color-profile", "toggle", root.registry.colorProfile === "colorful"),
        section("Frame", "Fake fullscreen frame and unified shadow treatment.", "lacuna"),
        row("corners", "Frame", "Draw Lacuna-owned frame pieces around the screen perimeter", frameModeName(), "lacuna", "", "segments", false, [
          { value: "off", label: "Off" },
          { value: "fullframe", label: "On" }
        ], root.registry.frameMode, "set-frame-mode-"),
        row("photo", "Frame Shadow", root.registry.frameShadow ? "Apply one cohesive shadow pass to the frame layer" : "Keep frame pieces fill-only", root.registry.frameShadow ? "On" : "Off", "lacuna", "toggle-frame-shadow", "toggle", root.registry.frameShadow),
        section("Omarchy", "Shortcuts for the host theme workflow.", "shell"),
        commandRow("palette", "Theme", "Switch Omarchy theme", root.registry.switchThemeCommand(), "shell"),
        commandRow("background", "Background", "Switch the active theme background", root.registry.switchBackgroundCommand(), "shell"),
        commandRow("photo", "Wallpaper Catalog", "Open wallpaper picker", "jobowalls-gui", "shell")
      ]
    }

    if (sectionId === "layout") {
      return [
        section("Sidebar", "Keep launcher behavior separate from Lacuna settings.", "lacuna"),
        row(root.registry.compact ? "density-compact" : "density-normal", "Lacuna Size", barSizeModeHint(), barSizeModeName(), "lacuna", "", "segments", false, [
          { value: "compact", label: "Compact" },
          { value: "full", label: "Full" }
        ], root.registry.barSizeMode, "set-bar-size-mode-"),
        row(root.registry.sidebarCollapsed ? "sidebar-expand" : "sidebar-collapse", "Sidebar Display", root.registry.sidebarDisplayHint(), sidebarShapeName(), "lacuna", "", "segments", false, [
          { value: "full", label: "Full" },
          { value: "rail", label: "Rail" }
        ], root.registry.sidebarDisplayMode(), "set-sidebar-display-"),
        row("sidebar-overlay", "Window Mode", root.registry.sidebarExclusive ? "Float over windows" : "Reserve screen space", sidebarModeName(), "lacuna", "toggle-sidebar-mode", "toggle", root.registry.sidebarExclusive),
        row("corners", "Corner Pieces", root.registry.sidebarCornerPieces ? "Rounded connector pieces are visible" : "Use a flat sidebar edge", root.registry.sidebarCornerPieces ? "On" : "Off", "lacuna", "toggle-corner-pieces", "toggle", root.registry.sidebarCornerPieces)
      ]
    }

    if (sectionId === "preferred-apps") {
      return [
        section("Launch Roles", "Rows open the shared app picker and preserve the reset-to-system option.", "lacuna"),
        row("folder", "Files", root.registry.preferredAppHint("files"), "Change", root.registry.roleMeta("files").tone, "choose-preferred-app-files", "button"),
        row("edit", "Editor", root.registry.preferredAppHint("editor"), "Change", root.registry.roleMeta("editor").tone, "choose-preferred-app-editor", "button"),
        row("mail", "Email", root.registry.preferredAppHint("email"), "Change", root.registry.roleMeta("email").tone, "choose-preferred-app-email", "button"),
        row("message", "Discord", root.registry.preferredAppHint("discord"), "Change", root.registry.roleMeta("discord").tone, "choose-preferred-app-discord", "button")
      ]
    }

    if (sectionId === "desktop-clock") {
      return [
        section("Activation", "Controls the separate desktop clock plugin entry.", "lacuna"),
        row("clock", "Desktop Clock", root.registry.desktopClockEnabled ? "Visible on the desktop layer" : "Hidden from the desktop layer", root.registry.desktopClockEnabled ? "On" : "Off", "lacuna", "toggle-desktop-clock", "toggle", root.registry.desktopClockEnabled),
        row("clock", "12-Hour Time", root.registry.desktopClockUse12Hour ? "Show 1:05 PM style time" : "Show 13:05 style time", root.registry.clockFormatHint(), "lacuna", "toggle-clock-12-hour", "toggle", root.registry.desktopClockUse12Hour),
        section("Position", "Anchor and nudge values are written inline to shell plugin state.", "lacuna"),
        row("clock", "Horizontal", "Anchor column", "", "lacuna", "", "segments", false, [
          { value: "left", label: "Left" },
          { value: "center", label: "Center" },
          { value: "right", label: "Right" }
        ], root.registry.anchorHorizontal(), "set-clock-anchor-x-"),
        row("clock", "Vertical", "Anchor row", "", "lacuna", "", "segments", false, [
          { value: "top", label: "Top" },
          { value: "center", label: "Center" },
          { value: "bottom", label: "Bottom" }
        ], root.registry.anchorVertical(), "set-clock-anchor-y-"),
        row("density-compact", "Scale Down", "Current scale " + clockScaleName(), "Smaller", "lacuna", "scale-clock-down", "button"),
        row("density-normal", "Scale Up", "Current scale " + clockScaleName(), "Larger", "lacuna", "scale-clock-up", "button"),
        row("arrow-left", "Move Left", "Nudge 24 px left", "Move", "lacuna", "nudge-clock-left", "button"),
        row("chevron-right", "Move Right", "Nudge 24 px right", "Move", "lacuna", "nudge-clock-right", "button"),
        row("arrow-up", "Move Up", "Nudge 24 px up", "Move", "lacuna", "nudge-clock-up", "button"),
        row("arrow-down", "Move Down", "Nudge 24 px down", "Move", "lacuna", "nudge-clock-down", "button"),
        row("refresh", "Reset Position", "Clear clock offsets, scale, and return to bottom-right", "Reset", "shell", "reset-clock-position", "button")
      ]
    }

    if (sectionId === "runtime") {
      return [
        section("Shell", "Operational commands for the live Omarchy shell.", "shell"),
        commandRow("refresh", "Restart Shell", "Restart Omarchy shell", root.registry.restartLacunaCommand(), "shell"),
        commandRow("file-search", "Open Log", "View the current shell log", root.registry.openLogCommand(), "shell"),
        row("refresh", "Reload App Catalog", "Rescan desktop launchers", "Reload", "shell", "reload-apps", "button"),
        commandRow("edit", "Open Plugin Source", "Edit the Lacuna plugin repository", root.registry.editPluginCommand(), "lacuna")
      ]
    }

    return [
      section("Lacuna", "Low-noise plugin metadata.", "lacuna"),
      row("lacuna", "Version", "", root.version !== "" ? root.version : "Unavailable", "lacuna", "", "value"),
      row("palette", "Active Theme", "", root.themeTitle !== "" ? root.themeTitle : "Omarchy theme", "shell", "", "value"),
      row("settings", "Color Profile", "", colorProfileName(), "lacuna", "", "value"),
      section("Source", root.registry.lacunaPath, "nav"),
      commandRow("edit", "Open Source", "Edit this plugin repository", root.registry.editPluginCommand(), "lacuna")
    ]
  }

  function handleEntry(entry) {
    if (!entry || entry.kind !== "row") return
    if (entry.settingsSection !== "") {
      currentSection = entry.settingsSection
      return
    }
    root.activated(entry)
  }

  width: 400
  height: 560
  clip: true
  focus: open
  Keys.onEscapePressed: root.closeRequested()

  Behavior on opacity {
    LacunaAnim { motion: "fast" }
  }

  FontLoader {
    id: itemFont

    source: "../assets/fonts/Tektur-SemiBold.ttf"
  }

  Shape {
    visible: root.drawBackground
    anchors.fill: parent
    asynchronous: true
    antialiasing: true
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      fillColor: root.background
      strokeWidth: 0
      startX: 0
      startY: 0

      PathLine { x: root.width - root.panelRadius; y: 0 }
      PathCubic {
        x: root.width
        y: root.panelRadius
        control1X: root.width - root.panelRadius * (1 - root.curveKappa)
        control1Y: 0
        control2X: root.width
        control2Y: root.panelRadius * (1 - root.curveKappa)
      }
      PathLine { x: root.width; y: root.height - root.panelRadius }
      PathCubic {
        x: root.width - root.panelRadius
        y: root.height
        control1X: root.width
        control1Y: root.height - root.panelRadius * (1 - root.curveKappa)
        control2X: root.width - root.panelRadius * (1 - root.curveKappa)
        control2Y: root.height
      }
      PathLine { x: 0; y: root.height }
      PathLine { x: 0; y: 0 }
    }
  }

  Item {
    anchors.fill: parent
    anchors.margins: root.compact ? 10 : 12

    SettingsRail {
      id: sectionRail

      anchors.top: parent.top
      anchors.bottom: parent.bottom
      anchors.left: parent.left
      sections: root.sections()
      currentSection: root.currentSection
      compact: root.compact
      foreground: root.foreground
      background: root.background
      muted: root.muted
      accent: root.accent
      designTokens: root.designTokens
      onSectionSelected: function(section) {
        root.currentSection = section
      }
    }

    Column {
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      anchors.left: sectionRail.right
      anchors.right: parent.right
      anchors.leftMargin: root.compact ? 9 : 12
      spacing: root.compact ? 8 : 10

      SettingsHeader {
        width: parent.width
        title: root.sectionMeta(root.currentSection).label
        subtitle: root.sectionMeta(root.currentSection).hint
        compact: root.compact
        foreground: root.foreground
        muted: root.muted
        accent: root.accent
        titleFontFamily: root.itemFontFamily
        bodyFontFamily: root.bodyFontFamily
        designTokens: root.designTokens
        onCloseRequested: root.closeRequested()
      }

      LacunaRect {
        width: parent.width
        height: 1
        color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08)
      }

      LacunaScrollView {
        width: parent.width
        height: Math.max(0, parent.height - y)
        showEdgeMasks: true
        edgeMaskColor: root.background

        Column {
          id: itemList

          width: parent.width
          spacing: root.compact ? 5 : 6

          Repeater {
            model: root.itemsFor(root.currentSection)

            Loader {
              property var entry: modelData

              width: parent.width
              sourceComponent: entry.kind === "section" ? sectionDelegate : rowDelegate
            }
          }
        }

        Component {
          id: sectionDelegate

          SettingsSection {
            width: parent ? parent.width : 0
            title: parent.entry.label
            note: parent.entry.note
            compact: root.compact
            foreground: root.foreground
            muted: root.muted
            accent: root.toneAccent(parent.entry.tone)
            fontFamily: root.bodyFontFamily
          }
        }

        Component {
          id: rowDelegate

          SettingsRow {
            width: parent.width
            icon: parent.entry.icon
            label: parent.entry.label
            hint: parent.entry.hint
            value: parent.entry.value
            tone: parent.entry.tone
            control: parent.entry.control
            checked: parent.entry.checked
            options: parent.entry.options
            optionValue: parent.entry.optionValue
            compact: root.compact
            foreground: root.foreground
            background: root.background
            muted: root.muted
            accent: root.accent
            toneAccent: root.toneAccent(parent.entry.tone)
            titleFontFamily: root.itemFontFamily
            bodyFontFamily: root.bodyFontFamily
            designTokens: root.designTokens
            onTriggered: root.handleEntry(parent.entry)
            onOptionSelected: function(value) {
              root.activated({
                kind: "item",
                action: parent.entry.optionActionPrefix + value,
                view: "",
                command: ""
              })
            }
          }
        }
      }
    }
  }

  DesignTokens {
    id: fallbackDesignTokens
    designStyle: "lacuna"
    compact: root.compact
    foreground: root.foreground
    background: root.background
    accent: root.accent
  }
}
