import QtQuick
import qs.Commons
import qs.Ui

Panel {
  id: root

  moduleName: "lacuna.bar-config"
  manageIpc: false

  property Item anchorItem: null
  readonly property bool editing: bar && bar.editMode === true
  readonly property color foreground: bar ? bar.foreground : Color.foreground

  function setEditing(value) {
    if (!bar) return
    if (value && typeof bar.enterEditMode === "function") bar.enterEditMode()
    else if (!value && typeof bar.exitEditMode === "function") bar.exitEditMode()
  }

  function finish() {
    setEditing(false)
    close()
  }

  onOpenedChanged: if (!opened) setEditing(false)

  KeyboardPanel {
    id: panel

    anchorItem: root.anchorItem
    owner: root
    bar: root.bar
    open: root.opened && root.anchorItem !== null
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(360))
    contentHeight: panel.fittedContentHeight(contentColumn.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher

      anchors.fill: parent
      onActivateRequested: root.setEditing(!root.editing)
      onCloseRequested: root.finish()

      Column {
        id: contentColumn

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(14)

        PanelSectionHeader {
          text: "LAYOUT"
          foreground: root.foreground
          fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
        }

        Toggle {
          width: parent.width
          label: "Edit bar layout"
          description: root.editing ? "Drag modules; Escape finishes" : "Enable module dragging"
          checked: root.editing
          foreground: root.foreground
          accent: Color.accent
          fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
          onClicked: root.setEditing(!root.editing)
        }
      }
    }
  }
}
