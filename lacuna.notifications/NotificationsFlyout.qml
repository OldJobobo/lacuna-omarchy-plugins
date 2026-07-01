import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

PopupWindow {
  id: root

  required property Item anchorItem
  required property QtObject bar
  property var owner: null
  property var service: null
  property bool open: false
  property int panelWidth: 420
  property int panelHeight: 500
  property int joinRadius: 13
  property int cornerRadius: 14
  property int margin: 8
  property color accentColor: "#89b4fa"
  property string fontFamily: bar ? bar.fontFamily : "Hack Nerd Font Propo"
  property string activeTab: pendingCount > 0 ? "pending" : "past"

  readonly property var anchorWindow: anchorItem ? anchorItem.QsWindow.window : null
  readonly property int contentPadding: 14
  readonly property int innerWidth: panelWidth - contentPadding * 2
  readonly property color surfaceBackground: opaqueColor(bar ? bar.background : "#101315")
  readonly property color panelColor: Qt.rgba(surfaceBackground.r, surfaceBackground.g, surfaceBackground.b, 0.98)
  readonly property color foreground: bar ? bar.foreground : "#d8dee9"
  readonly property color dimColor: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.60)
  readonly property color lineColor: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.14)
  readonly property color panelFill: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.045)
  readonly property color panelHover: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.12)
  readonly property bool dnd: service ? service.doNotDisturb : false
  readonly property int pendingCount: service ? service.pendingModel.count : 0
  readonly property int pastCount: service ? service.pastModel.count : 0
  readonly property bool showingPending: activeTab === "pending"
  readonly property var activeModel: !service ? null : (showingPending ? service.pendingModel : service.pastModel)

  function space(value) { return Math.round(Number(value || 0)) }
  function opaqueColor(colorValue) {
    var c = colorValue
    if (typeof c === "string") c = Qt.color(c)
    return Qt.rgba(c.r, c.g, c.b, 1)
  }
  function close() {
    if (owner && "close" in owner) owner.close()
    else root.open = false
  }
  function notificationIconSource(icon) {
    var value = String(icon || "")
    if (value.length === 0) return ""
    if (value.indexOf("file://") === 0 || value.indexOf("image://") === 0) return value
    if (value.charAt(0) === "/") return "file://" + value
    return ""
  }
  function sanitizeBody(value) {
    return String(value || "").replace(/<[^>]+>/g, "").replace(/&amp;/g, "&").replace(/&lt;/g, "<").replace(/&gt;/g, ">")
  }

  property real reveal: open ? 1 : 0
  Behavior on reveal { NumberAnimation { duration: 190; easing.type: Easing.OutCubic } }
  readonly property real contentOpacity: Math.max(0, Math.min(1, (reveal - 0.3) / 0.7))

  visible: open || reveal > 0.001
  color: "transparent"
  implicitWidth: surface.fullWidth
  implicitHeight: surface.implicitHeight
  onOpenChanged: {
    if (!bar) return
    if (open) {
      activeTab = pendingCount > 0 ? "pending" : "past"
      bar.requestPopout(root)
    } else if (bar.activePopout === root) {
      bar.releasePopout(root)
    }
  }

  HyprlandFocusGrab {
    active: root.open
    windows: root.anchorWindow ? [root, root.anchorWindow] : [root]
    onCleared: root.close()
  }

  anchor {
    id: popupAnchor
    window: root.anchorItem ? root.anchorItem.QsWindow.window : null
    adjustment: PopupAdjustment.Slide
    edges: Edges.Top | Edges.Left
    gravity: root.bar && root.bar.position === "bottom" ? Edges.Top | Edges.Right : Edges.Bottom | Edges.Right
    rect.width: 1
    rect.height: 1
    onAnchoring: {
      if (!root.anchorItem || !root.bar) return
      var target = root.anchorItem
      var window = target.QsWindow.window
      if (!window) return
      var below = root.bar.position !== "bottom"
      var point = window.contentItem.mapFromItem(target, target.width / 2 - (root.joinRadius + root.panelWidth / 2), below ? target.height : -root.implicitHeight)
      point.x = Math.max(root.margin, Math.min(point.x, window.width - root.implicitWidth - root.margin))
      popupAnchor.rect.x = Math.round(point.x)
      popupAnchor.rect.y = Math.round(point.y)
    }
  }

  Item {
    anchors.top: parent.top
    width: parent.width
    height: Math.round(root.implicitHeight * root.reveal)
    clip: true

    Item {
      width: root.implicitWidth
      height: root.implicitHeight

      BarFlyoutSurface {
        id: surface
        panelWidth: root.panelWidth
        panelHeight: root.panelHeight
        joinRadius: root.joinRadius
        cornerRadius: root.cornerRadius
        panelColor: root.panelColor
      }

      Column {
        x: surface.panelLeft + root.contentPadding
        y: surface.panelTop + root.contentPadding
        width: root.innerWidth
        height: root.panelHeight - root.contentPadding * 2
        opacity: root.contentOpacity
        spacing: root.space(10)

        Row {
          width: parent.width
          height: root.space(34)
          spacing: root.space(8)

          Text {
            width: parent.width - dndButton.width - parent.spacing
            anchors.verticalCenter: parent.verticalCenter
            text: "Notifications"
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: 16
            font.bold: true
            elide: Text.ElideRight
          }

          Rectangle {
            id: dndButton
            width: dndText.implicitWidth + root.space(18)
            height: root.space(26)
            anchors.verticalCenter: parent.verticalCenter
            radius: 0
            color: dndArea.containsMouse ? root.panelHover : (root.dnd ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.18) : root.panelFill)
            border.width: 1
            border.color: root.dnd ? root.accentColor : root.lineColor

            Text {
              id: dndText
              anchors.centerIn: parent
              text: root.dnd ? "DND on" : "DND off"
              color: root.dnd ? root.accentColor : root.dimColor
              font.family: root.fontFamily
              font.pixelSize: 11
              font.bold: true
            }

            MouseArea {
              id: dndArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: if (root.service) root.service.setDoNotDisturb(!root.service.doNotDisturb)
            }
          }
        }

        Row {
          width: parent.width
          height: root.space(32)
          spacing: 0

          Repeater {
            model: [
              { key: "pending", label: "Pending", count: root.pendingCount },
              { key: "past", label: "Recently", count: root.pastCount }
            ]
            delegate: Item {
              required property var modelData
              width: parent.width / 2
              height: parent.height
              readonly property bool selected: root.activeTab === modelData.key

              Text {
                anchors.centerIn: parent
                text: modelData.label + (modelData.count > 0 ? "  " + modelData.count : "")
                color: parent.selected ? root.foreground : root.dimColor
                font.family: root.fontFamily
                font.pixelSize: 12
                font.bold: parent.selected
              }

              Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: parent.selected ? 2 : 1
                color: parent.selected ? root.accentColor : root.lineColor
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.activeTab = modelData.key
              }
            }
          }
        }

        Row {
          width: parent.width
          height: root.space(28)
          visible: listView.count > 0

          Item { width: parent.width - actionButton.width; height: 1 }

          Rectangle {
            id: actionButton
            width: actionText.implicitWidth + root.space(18)
            height: root.space(24)
            radius: 0
            color: actionArea.containsMouse ? root.panelHover : "transparent"
            border.width: 1
            border.color: root.lineColor

            Text {
              id: actionText
              anchors.centerIn: parent
              text: root.showingPending ? "Mark all as seen" : "Clear recent"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: 11
            }

            MouseArea {
              id: actionArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (!root.service) return
                if (root.showingPending) root.service.markAllSeen()
                else root.service.clearPast()
              }
            }
          }
        }

        ListView {
          id: listView
          width: parent.width
          height: parent.height - y
          clip: true
          spacing: root.space(8)
          model: root.activeModel
          visible: count > 0

          delegate: Rectangle {
            id: rowCard
            required property int index
            required property string app
            required property string appIcon
            required property string summary
            required property string body
            required property string image

            readonly property string cleanBody: root.sanitizeBody(body)
            readonly property bool hasMedia: image.length > 0 && (image.indexOf("file://") === 0 || image.indexOf("image://") === 0)
            readonly property string imageSource: hasMedia ? image : root.notificationIconSource(appIcon)

            width: listView.width
            height: Math.max(root.space(62), rowText.implicitHeight + root.space(20))
            radius: 0
            color: closeArea.containsMouse ? Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.065) : root.panelFill
            border.width: 1
            border.color: root.lineColor

            Item {
              id: imageSlot
              anchors.left: parent.left
              anchors.leftMargin: root.space(10)
              anchors.verticalCenter: parent.verticalCenter
              width: root.space(34)
              height: root.space(34)
              visible: rowImage.source !== "" && rowImage.status !== Image.Error

              Image {
                id: rowImage
                anchors.fill: parent
                source: rowCard.imageSource
                fillMode: rowCard.hasMedia ? Image.PreserveAspectCrop : Image.PreserveAspectFit
                asynchronous: true
                smooth: true
              }
            }

            Column {
              id: rowText
              anchors.left: imageSlot.visible ? imageSlot.right : parent.left
              anchors.leftMargin: root.space(10)
              anchors.right: closeButton.left
              anchors.rightMargin: root.space(8)
              anchors.verticalCenter: parent.verticalCenter
              spacing: root.space(3)

              Text {
                width: parent.width
                text: rowCard.summary || "Notification"
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: 13
                font.bold: true
                elide: Text.ElideRight
                maximumLineCount: 1
              }

              Text {
                width: parent.width
                visible: rowCard.cleanBody.length > 0
                text: rowCard.cleanBody
                color: root.dimColor
                font.family: root.fontFamily
                font.pixelSize: 11
                textFormat: Text.PlainText
                wrapMode: Text.WordWrap
                elide: Text.ElideRight
                maximumLineCount: 2
              }
            }

            Rectangle {
              id: closeButton
              anchors.right: parent.right
              anchors.rightMargin: root.space(8)
              anchors.verticalCenter: parent.verticalCenter
              width: root.space(22)
              height: root.space(22)
              radius: 0
              color: closeArea.containsMouse ? root.lineColor : "transparent"

              Text {
                anchors.centerIn: parent
                text: "x"
                color: root.dimColor
                font.family: root.fontFamily
                font.pixelSize: 12
              }

              MouseArea {
                id: closeArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (!root.service) return
                  if (root.showingPending) root.service.dismissPending(rowCard.index)
                  else root.service.dismissPast(rowCard.index)
                }
              }
            }
          }
        }

        Item {
          width: parent.width
          height: parent.height - y
          visible: listView.count === 0

          Column {
            anchors.centerIn: parent
            spacing: root.space(8)

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "󰂚"
              color: root.lineColor
              font.family: root.fontFamily
              font.pixelSize: 34
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: root.showingPending ? "Nothing waiting" : "Nothing recent"
              color: root.dimColor
              font.family: root.fontFamily
              font.pixelSize: 13
            }
          }
        }
      }
    }
  }
}
