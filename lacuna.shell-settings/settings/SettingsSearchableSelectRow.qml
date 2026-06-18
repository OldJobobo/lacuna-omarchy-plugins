import QtQuick
import QtQuick.Controls
import "../components"

Item {
  id: root

  signal selected(string value)

  property string icon: ""
  property string label: ""
  property string hint: ""
  property string currentValue: ""
  property string placeholder: "Search"
  property var options: []
  property bool compact: false
  property color foreground: "#d8dee9"
  property color background: "#101315"
  property color muted: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.48)
  property color toneAccent: "#88c0d0"
  property string titleFontFamily: "Tektur"
  property string bodyFontFamily: "Hack Nerd Font Propo"
  property var designTokens: null
  property bool expanded: false
  property string searchText: ""

  readonly property int rowHeight: compact ? 46 : 52
  readonly property int optionHeight: compact ? 28 : 30
  readonly property int searchHeight: compact ? 28 : 31
  readonly property int maxVisibleOptions: 6
  readonly property var filteredOptions: filterOptions()
  readonly property int dropHeight: expanded ? searchHeight + 10 + Math.min(filteredOptions.length, maxVisibleOptions) * optionHeight : 0
  readonly property int trailingWidth: compact ? 142 : 176

  function optionLabel(value) {
    for (var i = 0; i < options.length; i++) {
      if (String(options[i].value) === String(value)) return options[i].label || String(value)
    }
    return placeholder
  }

  function filterOptions() {
    var rows = []
    var query = searchText.trim().toLowerCase()
    for (var i = 0; i < options.length; i++) {
      var item = options[i]
      var label = String(item.label || item.value || "")
      if (query === "" || label.toLowerCase().indexOf(query) !== -1) rows.push(item)
      if (rows.length >= 80) break
    }
    return rows
  }

  width: parent ? parent.width : implicitWidth
  height: rowHeight + dropHeight
  clip: true

  LacunaRect {
    id: rowShell
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: root.rowHeight
    radius: root.designTokens ? root.designTokens.controlRadius : 0
    color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.025 + stateLayer.reveal * 0.03)
    border.width: root.expanded || (root.designTokens && root.designTokens.omarchy && stateLayer.containsMouse) ? 1 : 0
    border.color: root.expanded ? Qt.rgba(root.toneAccent.r, root.toneAccent.g, root.toneAccent.b, 0.38) : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.14)

    LacunaStateLayer {
      id: stateLayer
      stateColor: root.toneAccent
      hoverOpacity: root.designTokens ? root.designTokens.hoverOpacity : 0.06
      pressOpacity: root.designTokens ? root.designTokens.activeOpacity : 0.11
      showFill: false
      onTriggered: {
        root.expanded = !root.expanded
        if (root.expanded) Qt.callLater(function() { searchInput.forceActiveFocus() })
      }
    }

    Row {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: root.compact ? 8 : 10
      anchors.rightMargin: root.compact ? 8 : 10
      spacing: root.compact ? 7 : 9

      Item {
        width: root.compact ? 24 : 28
        height: root.rowHeight

        LacunaTablerIcon {
          anchors.centerIn: parent
          name: root.icon
          color: stateLayer.containsMouse || root.expanded ? root.toneAccent : root.muted
          iconSize: root.compact ? 14 : 16
        }
      }

      Column {
        width: Math.max(0, parent.width - (root.compact ? 24 : 28) - root.trailingWidth - parent.spacing * 2)
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        LacunaText {
          width: parent.width
          text: root.label
          color: root.foreground
          fontFamily: root.titleFontFamily
          font.pixelSize: root.compact ? 12 : 13
          font.weight: Font.DemiBold
        }

        LacunaText {
          visible: root.hint !== ""
          width: parent.width
          text: root.hint
          color: root.muted
          fontFamily: root.bodyFontFamily
          font.pixelSize: root.compact ? 9 : 10
        }
      }

      LacunaRect {
        width: root.trailingWidth
        height: root.compact ? 26 : 28
        anchors.verticalCenter: parent.verticalCenter
        radius: root.designTokens ? root.designTokens.controlRadius : 0
        color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.045)
        border.width: 1
        border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.13)
        clip: true

        LacunaText {
          anchors.left: parent.left
          anchors.right: chevron.left
          anchors.verticalCenter: parent.verticalCenter
          anchors.leftMargin: 8
          anchors.rightMargin: 4
          text: root.optionLabel(root.currentValue)
          color: root.currentValue === "" ? root.muted : root.foreground
          fontFamily: root.bodyFontFamily
          font.pixelSize: root.compact ? 9 : 10
        }

        LacunaTablerIcon {
          id: chevron
          anchors.right: parent.right
          anchors.rightMargin: 6
          anchors.verticalCenter: parent.verticalCenter
          name: root.expanded ? "chevron-up" : "chevron-down"
          color: root.toneAccent
          iconSize: root.compact ? 12 : 14
        }
      }
    }
  }

  LacunaRect {
    visible: root.expanded
    anchors.top: rowShell.bottom
    anchors.topMargin: 4
    anchors.left: parent.left
    anchors.right: parent.right
    height: Math.max(0, root.dropHeight - 4)
    radius: root.designTokens ? root.designTokens.controlRadius : 0
    color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.035)
    border.width: 1
    border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.10)
    clip: true

    LacunaRect {
      id: searchBox
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.margins: 4
      height: root.searchHeight
      radius: root.designTokens ? root.designTokens.controlRadius : 0
      color: Qt.rgba(root.background.r, root.background.g, root.background.b, 0.28)
      border.width: 1
      border.color: searchInput.activeFocus ? Qt.rgba(root.toneAccent.r, root.toneAccent.g, root.toneAccent.b, 0.44) : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.12)

      LacunaTablerIcon {
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        name: "search"
        color: root.muted
        iconSize: root.compact ? 12 : 14
      }

      TextInput {
        id: searchInput
        anchors.left: parent.left
        anchors.leftMargin: 28
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: root.searchText
        color: root.foreground
        selectionColor: Qt.rgba(root.toneAccent.r, root.toneAccent.g, root.toneAccent.b, 0.35)
        selectedTextColor: root.foreground
        font.family: root.bodyFontFamily
        font.pixelSize: root.compact ? 10 : 11
        clip: true
        onTextChanged: root.searchText = text
        Keys.onEscapePressed: {
          root.expanded = false
          root.searchText = ""
        }
      }
    }

    ListView {
      anchors.top: searchBox.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      anchors.margins: 4
      clip: true
      model: root.filteredOptions
      boundsBehavior: Flickable.StopAtBounds

      delegate: LacunaRect {
        required property var modelData

        width: ListView.view.width
        height: root.optionHeight
        radius: root.designTokens ? root.designTokens.controlRadius : 0
        color: String(modelData.value) === root.currentValue
          ? Qt.rgba(root.toneAccent.r, root.toneAccent.g, root.toneAccent.b, 0.18)
          : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, optionLayer.reveal * 0.04)

        LacunaText {
          anchors.left: parent.left
          anchors.right: check.left
          anchors.verticalCenter: parent.verticalCenter
          anchors.leftMargin: 8
          anchors.rightMargin: 8
          text: modelData.label || modelData.value
          color: root.foreground
          fontFamily: root.bodyFontFamily
          font.pixelSize: root.compact ? 9 : 10
        }

        LacunaTablerIcon {
          id: check
          anchors.right: parent.right
          anchors.rightMargin: 8
          anchors.verticalCenter: parent.verticalCenter
          name: String(modelData.value) === root.currentValue ? "check" : "circle"
          color: String(modelData.value) === root.currentValue ? root.toneAccent : root.muted
          iconSize: root.compact ? 12 : 14
        }

        LacunaStateLayer {
          id: optionLayer
          stateColor: root.toneAccent
          hoverOpacity: root.designTokens ? root.designTokens.hoverOpacity : 0.06
          pressOpacity: root.designTokens ? root.designTokens.activeOpacity : 0.11
          onTriggered: {
            root.selected(String(modelData.value))
            root.expanded = false
            root.searchText = ""
          }
        }
      }
    }
  }
}
