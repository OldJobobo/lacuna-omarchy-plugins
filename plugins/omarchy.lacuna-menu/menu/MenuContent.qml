import QtQuick
import "../components"
import "../modules"
import "../services"

Column {
  id: root

  signal activated(var entry)
  signal collapseRequested()
  signal settingsRequested()

  required property var menuState
  required property var registry
  property bool open: true
  property bool compact: false
  property string currentView: menuState.currentView
  property string version: ""
  property real viewProgress: 1
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
  property int iconRailWidth: 32
  property var designTokens: fallbackDesignTokens
  property var collapsedSections: ({})
  property int sectionRevision: 0

  function toneAccent(tone) {
    if (tone === "lacuna") return root.accent
    if (tone === "shell") return root.shellAccent
    if (tone === "session") return root.sessionAccent
    if (tone === "danger") return root.dangerAccent
    return root.navAccent
  }

  function openSettings() {
    root.settingsRequested()
  }

  function sectionKey(entry, index) {
    return root.menuState.currentView + "::" + String(entry.label || entry.group || "section").toLowerCase() + "::" + index
  }

  function isSectionCollapsed(key) {
    var revision = root.sectionRevision
    return root.collapsedSections && root.collapsedSections[key] === true
  }

  function toggleSection(key) {
    var next = {}
    for (var existingKey in root.collapsedSections) next[existingKey] = root.collapsedSections[existingKey]
    next[key] = !isSectionCollapsed(key)
    root.collapsedSections = next
    root.sectionRevision++
  }

  function visibleItems() {
    var revision = root.sectionRevision
    var source = root.registry.itemsFor(root.menuState.currentView)
    var counts = {}
    var headerIndex = 0
    var activeKey = ""

    for (var i = 0; i < source.length; i++) {
      var sourceEntry = source[i]
      if (sourceEntry.kind === "header") {
        activeKey = sectionKey(sourceEntry, headerIndex)
        counts[activeKey] = 0
        headerIndex++
      } else if (activeKey !== "") {
        counts[activeKey]++
      }
    }

    var rows = []
    headerIndex = 0
    activeKey = ""
    var activeCollapsed = false

    for (var j = 0; j < source.length; j++) {
      var entry = source[j]
      if (entry.kind === "header") {
        activeKey = sectionKey(entry, headerIndex)
        activeCollapsed = isSectionCollapsed(activeKey)
        var header = {}
        for (var key in entry) header[key] = entry[key]
        header.sectionKey = activeKey
        header.sectionCollapsed = activeCollapsed
        header.sectionCount = counts[activeKey] || 0
        rows.push(header)
        headerIndex++
      } else if (!activeCollapsed) {
        rows.push(entry)
      }
    }

    return rows
  }

  spacing: designTokens.sectionSpacing
  onCurrentViewChanged: {
    viewProgress = 0
    viewReveal.restart()
  }

  opacity: open ? viewProgress : 0
  x: open ? -6 * (1 - viewProgress) : -6

  Behavior on opacity {
    LacunaAnim { motion: "normal" }
  }

  NumberAnimation {
    id: viewReveal

    target: root
    property: "viewProgress"
    to: 1
    duration: 180
    easing.type: Easing.OutCubic
  }

  FontLoader {
    id: itemFont

    source: "../assets/fonts/Tektur-SemiBold.ttf"
  }

  MenuHeader {
    width: parent.width
    title: root.registry.titleFor(root.menuState.currentView)
    version: root.version
    subtitle: ""
    canGoBack: root.menuState.stack.length > 1
    foreground: root.foreground
    muted: root.muted
    accent: root.accent
    danger: root.dangerAccent
    compact: root.compact
    designTokens: root.designTokens
    bodyFontFamily: root.bodyFontFamily
    onBackRequested: root.menuState.back()
    onCollapseRequested: root.collapseRequested()
    onCloseRequested: root.menuState.close()
  }

  LacunaRect {
    width: parent.width
    height: 1
    color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.07)
    opacity: root.designTokens.headerTreatment === "accent-line" ? 1 : 0.55
  }

  Flickable {
    width: parent.width
    height: Math.max(0, root.height - y - settingsFooter.height - root.spacing)
    contentWidth: width
    contentHeight: itemList.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Column {
      id: itemList

      width: parent.width
      spacing: root.designTokens.itemSpacing

      Repeater {
        model: root.visibleItems()

        Loader {
          property var entry: modelData

          width: parent.width
          sourceComponent: entry.kind === "header" ? sectionDelegate : itemDelegate
        }
      }
    }

    Component {
      id: sectionDelegate

      MenuSection {
        width: parent ? parent.width : 0
        title: parent.entry.label
        foreground: root.foreground
        muted: root.muted
        accent: root.toneAccent(parent.entry.tone)
        band: parent.entry.tone === "lacuna" || parent.entry.tone === "danger"
        collapsible: parent.entry.sectionCount > 0
        collapsed: parent.entry.sectionCollapsed || false
        count: parent.entry.sectionCount || 0
        compact: root.compact
        fontFamily: root.bodyFontFamily
        hoverOpacity: root.designTokens.hoverOpacity
        pressOpacity: root.designTokens.activeOpacity
        onToggled: root.toggleSection(parent.entry.sectionKey)
      }
    }

    Component {
      id: itemDelegate

      LacunaMenuItem {
        width: parent.width
        kind: parent.entry.kind
        icon: parent.entry.icon
        iconSource: parent.entry.iconSource || ""
        label: parent.entry.label
        hint: parent.entry.hint
        hasChildren: parent.entry.view !== ""
        foreground: root.foreground
        muted: root.muted
        accent: root.accent
        tone: parent.entry.tone
        toneAccent: root.toneAccent(parent.entry.tone)
        priority: parent.entry.priority
        layout: parent.entry.layout
        danger: parent.entry.danger
        switchVisible: parent.entry.switchVisible || false
        switchChecked: parent.entry.switchChecked || false
        badgeText: parent.entry.badgeText || ""
        trailingAction: parent.entry.trailingAction || ""
        trailingIcon: parent.entry.trailingIcon || ""
        trailingTooltip: parent.entry.trailingTooltip || ""
        optionValue: parent.entry.optionValue || ""
        options: parent.entry.options || []
        background: root.background
        fontFamily: root.bodyFontFamily
        labelFontFamily: root.itemFontFamily
        iconRailWidth: root.iconRailWidth
        compact: root.compact
        designTokens: root.designTokens
        onTriggered: root.activated(parent.entry)
        onTrailingActionTriggered: function(action) {
          var next = {
            kind: parent.entry.kind,
            action: action,
            appId: parent.entry.appId || "",
            view: "",
            command: ""
          }
          root.activated(next)
        }
        onOptionSelected: function(value) {
          root.activated({
            kind: "item",
            action: (parent.entry.optionActionPrefix || "set-design-style-") + value,
            view: "",
            command: ""
          })
        }
      }
    }
  }

  Item {
    id: settingsFooter

    width: parent.width
    height: root.compact ? 34 : 40

    LacunaRect {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      height: 1
      color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08)
    }

    Row {
      id: settingsRow

      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      height: root.compact ? 28 : 32

      LacunaIconButton {
        id: settingsButton

        anchors.verticalCenter: parent.verticalCenter
        icon: "gear"
        foreground: root.foreground
        muted: root.muted
        accent: root.accent
        hoverAccent: root.accent
        buttonSize: root.compact ? 26 : 30
        buttonRadius: root.designTokens.controlRadius
        hoverOpacity: root.designTokens.hoverOpacity
        pressOpacity: root.designTokens.activeOpacity
        iconSize: root.compact ? 14 : 16
        onTriggered: root.openSettings()
      }
    }

    LacunaRect {
      visible: settingsButton.hovered
      x: settingsRow.x + settingsButton.x + settingsButton.width + 8
      y: settingsRow.y + settingsButton.y - height - 4
      width: 118
      height: 28
      radius: root.designTokens.tooltipTreatment === "tonal" ? root.designTokens.radius : 0
      color: root.background
      border.width: root.designTokens.tooltipTreatment === "accent-strip" ? 1 : root.designTokens.borderWidth
      border.color: root.designTokens.tooltipTreatment === "bordered" ? Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.22) : Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.24)

      LacunaRect {
        visible: root.designTokens.tooltipTreatment === "accent-strip"
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 2
        color: root.accent
        opacity: 0.82
      }

      LacunaText {
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        text: "Lacuna Settings"
        color: root.foreground
        fontFamily: root.bodyFontFamily
        font.pixelSize: 11
        font.weight: Font.DemiBold
        elide: Text.ElideRight
      }
    }
  }

  DesignTokens {
    id: fallbackDesignTokens
    designStyle: "carbon"
    compact: root.compact
    foreground: root.foreground
    background: root.background
    accent: root.accent
  }
}
