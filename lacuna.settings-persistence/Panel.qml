import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Ui

Item {
  id: root

  property string omarchyPath: Quickshell.env("OMARCHY_PATH")
  property var shell: null
  property var manifest: null
  property var service: null
  property bool closingFromHost: false

  readonly property bool manageIdle: service ? service.manageIdle : true
  readonly property bool manageNightlight: service ? service.manageNightlight : true
  readonly property string statusText: service && service.lastError !== "" ? service.lastError
    : service ? service.lastStatus : "loading"

  function open(payloadJson) {
    closingFromHost = false
    window.visible = true
  }

  function close() {
    closingFromHost = true
    window.visible = false
    closingFromHost = false
  }

  function setManaged(idle, nightlight) {
    if (!idle && !nightlight) return
    if (service && typeof service.setManagedToggles === "function")
      service.setManagedToggles(idle, nightlight)
  }

  FloatingWindow {
    id: window

    title: "Lacuna Settings Persistence"
    color: Color.background
    visible: false
    implicitWidth: Style.space(440)
    implicitHeight: Style.space(290)
    minimumSize: Qt.size(Style.space(380), Style.space(240))

    onVisibleChanged: {
      if (!visible && !root.closingFromHost && root.shell && typeof root.shell.hide === "function")
        root.shell.hide("lacuna.settings-persistence")
    }

    Rectangle {
      anchors.fill: parent
      color: Color.background

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: Style.spacing.panelPadding
        spacing: Style.spacing.rowGap

        Text {
          Layout.fillWidth: true
          text: "Lacuna Settings Persistence"
          color: Color.foreground
          font.family: Style.font.family
          font.pixelSize: Style.font.title
          font.bold: true
          elide: Text.ElideRight
        }

        PanelSectionHeader {
          Layout.fillWidth: true
          text: "Managed Toggles"
        }

        Toggle {
          Layout.fillWidth: true
          label: "Idle Inhibit"
          description: "Restore stay-awake state after shell restart."
          checked: root.manageIdle
          onClicked: root.setManaged(!root.manageIdle, root.manageNightlight)
        }

        Toggle {
          Layout.fillWidth: true
          label: "Nightlight"
          description: "Restore Hyprsunset nightlight state after shell restart."
          checked: root.manageNightlight
          onClicked: root.setManaged(root.manageIdle, !root.manageNightlight)
        }

        Item { Layout.fillHeight: true }

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.spacing.rowGap

          Text {
            Layout.fillWidth: true
            text: root.statusText
            color: Color.foreground
            opacity: 0.72
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            elide: Text.ElideRight
          }

          Button {
            text: "Restore Now"
            foreground: Color.foreground
            focusable: true
            bordered: true
            onClicked: if (root.service && typeof root.service.requestManagedStatus === "function")
              root.service.requestManagedStatus("restore")
          }

          Button {
            text: "Close"
            foreground: Color.foreground
            focusable: true
            bordered: true
            onClicked: root.close()
          }
        }
      }
    }
  }
}
