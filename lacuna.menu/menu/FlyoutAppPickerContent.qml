import Quickshell.Widgets
import QtQuick
import "../components"
import "../services"

Column {
  id: root

  signal closeRequested()
  signal systemSelected()
  signal appSelected(string appId)

  required property var registry
  property var appCatalog: null
  property var customQuickLaunchApps: []
  property var preferredApps: ({})
  property bool compact: false
  property bool open: false
  property bool contentVisible: false
  property string mode: "customQuickLaunchApp"
  property string preferredRole: ""
  property string query: ""
  property color foreground: "#d8dee9"
  property color background: "#101315"
  property color accent: "#88c0d0"
  property color muted: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.48)
  property var designTokens: fallbackDesignTokens

  function resetSearch() {
    query = ""
    searchInput.text = ""
  }

  function forceSearchFocus() {
    searchInput.forceActiveFocus()
  }

  function roleValue(role) {
    var defaults = preferredApps || {}
    var value = String(defaults[role] || "").trim()
    return value === "" ? "system" : value
  }

  function containsQuickLaunch(id) {
    var ids = customQuickLaunchApps || []
    for (var i = 0; i < ids.length; i++) {
      if (String(ids[i]) === String(id)) return true
    }
    return false
  }

  function filteredApps() {
    var apps = appCatalog && appCatalog.apps ? appCatalog.apps : []
    var needle = query.toLowerCase().trim()
    var list = []

    for (var i = 0; i < apps.length; i++) {
      var app = apps[i]
      var haystack = String((app.Name || "") + " " + (app.GenericName || "") + " " + (app.Comment || "") + " " + (app.Categories || "")).toLowerCase()
      if (needle === "" || haystack.indexOf(needle) >= 0) list.push(app)
    }

    return list
  }

  visible: contentVisible
  enabled: open
  opacity: open ? 1 : 0
  anchors.margins: compact ? 10 : 12
  spacing: compact ? 8 : 10

  Behavior on opacity {
    LacunaAnim { motion: "fast" }
  }

  Row {
    width: parent.width
    height: root.compact ? 26 : 30
    spacing: 8

    LacunaText {
      width: parent.width - closePicker.width - parent.spacing
      anchors.verticalCenter: parent.verticalCenter
      text: root.mode === "preferredApp" ? "Set " + root.registry.roleMeta(root.preferredRole).label + " App" : "Add Quick Launch App"
      color: root.foreground
      fontFamily: "Tektur"
      font.pixelSize: root.compact ? 13 : 15
      font.weight: Font.DemiBold
    }

    LacunaIconButton {
      id: closePicker

      icon: "x"
      foreground: root.foreground
      muted: root.muted
      accent: root.accent
      hoverAccent: root.accent
      buttonSize: root.compact ? 24 : 28
      buttonRadius: root.designTokens.controlRadius
      hoverOpacity: root.designTokens.hoverOpacity
      pressOpacity: root.designTokens.activeOpacity
      iconSize: root.compact ? 13 : 15
      onTriggered: root.closeRequested()
    }
  }

  LacunaRect {
    width: parent.width
    height: root.compact ? 28 : 32
    radius: root.designTokens.material ? height / 2 : root.designTokens.controlRadius
    color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.07)
    border.width: 1
    border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.14)

    LacunaText {
      visible: searchInput.text === ""
      anchors.left: parent.left
      anchors.leftMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      text: "Search apps"
      color: root.muted
      fontFamily: "Hack Nerd Font Propo"
      font.pixelSize: root.compact ? 10 : 11
    }

    TextInput {
      id: searchInput

      anchors.fill: parent
      anchors.leftMargin: 10
      anchors.rightMargin: 10
      focus: root.open
      activeFocusOnPress: true
      color: root.foreground
      selectedTextColor: root.background
      selectionColor: root.accent
      font.family: "Hack Nerd Font Propo"
      font.pixelSize: root.compact ? 10 : 11
      verticalAlignment: TextInput.AlignVCenter
      clip: true
      onTextChanged: root.query = text
    }
  }

  LacunaScrollView {
    id: appPickerFlick

    width: parent.width
    height: Math.max(0, parent.height - y)
    spacing: root.compact ? 4 : 5
    showEdgeMasks: true
    edgeMaskColor: root.background

    LacunaRect {
      visible: root.mode === "preferredApp"
      width: parent.width
      height: visible ? (root.compact ? 32 : 38) : 0
      radius: root.designTokens.radius
      color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, systemPickerMouse.reveal * 0.10)
      border.width: root.roleValue(root.preferredRole) === "system" && !root.designTokens.lacuna ? 1 : 0
      border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.30)
      clip: true

      LacunaTablerIcon {
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        width: 22
        height: 22
        name: "settings"
        color: root.accent
        iconSize: root.compact ? 13 : 15
      }

      LacunaText {
        anchors.left: parent.left
        anchors.leftMargin: 42
        anchors.right: systemState.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: root.registry.roleMeta(root.preferredRole).systemHint
        color: root.foreground
        fontFamily: "Hack Nerd Font Propo"
        font.pixelSize: root.compact ? 10 : 11
        font.weight: systemPickerMouse.containsMouse ? Font.DemiBold : Font.Normal
        elide: Text.ElideRight
        maximumLineCount: 1
      }

      Item {
        id: systemState

        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        width: 18
        height: 18

        LacunaTablerIcon {
          visible: root.roleValue(root.preferredRole) === "system"
          anchors.centerIn: parent
          name: "check"
          color: root.accent
          iconSize: root.compact ? 12 : 14
        }
      }

      LacunaStateLayer {
        id: systemPickerMouse

        anchors.fill: parent
        stateColor: root.accent
        hoverOpacity: root.designTokens.hoverOpacity
        pressOpacity: root.designTokens.activeOpacity
        acceptWheel: true
        onTriggered: root.systemSelected()
        onScrolled: function(delta) {
          appPickerFlick.scrollBy(delta)
        }
      }
    }

    Repeater {
      model: root.contentVisible ? root.filteredApps() : []

      LacunaRect {
        required property var modelData

        readonly property bool alreadyAdded: root.mode === "customQuickLaunchApp" && root.containsQuickLaunch(modelData.id)
        readonly property bool selectedOverride: root.mode === "preferredApp" && root.roleValue(root.preferredRole) === String(modelData.id)
        width: parent.width
        height: root.compact ? 32 : 38
        radius: root.designTokens.radius
        color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, pickerMouse.reveal * 0.10)
        border.width: (alreadyAdded || selectedOverride) && !root.designTokens.lacuna ? 1 : 0
        border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.26)
        clip: true

        IconImage {
          id: pickerIcon

          anchors.left: parent.left
          anchors.leftMargin: 8
          anchors.verticalCenter: parent.verticalCenter
          width: root.compact ? 15 : 18
          height: width
          implicitSize: width
          source: root.registry.appIconSource(modelData)
          visible: source !== "" && status !== Image.Error
        }

        LacunaTablerIcon {
          anchors.centerIn: pickerIcon
          visible: pickerIcon.source === "" || pickerIcon.status === Image.Error
          name: root.registry.appIcon(modelData)
          color: alreadyAdded ? root.muted : root.accent
          iconSize: root.compact ? 13 : 15
        }

        LacunaText {
          anchors.left: pickerIcon.right
          anchors.leftMargin: 8
          anchors.right: addState.left
          anchors.rightMargin: 8
          anchors.verticalCenter: parent.verticalCenter
          text: modelData.Name || modelData.id
          color: alreadyAdded ? root.muted : root.foreground
          fontFamily: "Hack Nerd Font Propo"
          font.pixelSize: root.compact ? 10 : 11
          font.weight: pickerMouse.containsMouse ? Font.DemiBold : Font.Normal
          elide: Text.ElideRight
          maximumLineCount: 1
        }

        Item {
          id: addState

          anchors.right: parent.right
          anchors.rightMargin: 10
          anchors.verticalCenter: parent.verticalCenter
          width: 18
          height: 18

          LacunaTablerIcon {
            visible: alreadyAdded || selectedOverride || root.mode === "customQuickLaunchApp"
            anchors.centerIn: parent
            name: alreadyAdded || selectedOverride ? "check" : "plus"
            color: alreadyAdded ? root.muted : root.accent
            iconSize: root.compact ? 12 : 14
          }
        }

        LacunaStateLayer {
          id: pickerMouse

          anchors.fill: parent
          stateColor: root.accent
          hoverOpacity: root.designTokens.hoverOpacity
          pressOpacity: root.designTokens.activeOpacity
          acceptWheel: true
          onTriggered: root.appSelected(modelData.id)
          onScrolled: function(delta) {
            appPickerFlick.scrollBy(delta)
          }
        }
      }
    }
  }

  DesignTokens {
    id: fallbackDesignTokens

    compact: root.compact
    foreground: root.foreground
    background: root.background
    accent: root.accent
  }
}
