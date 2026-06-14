import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
  id: root

  property var targetScreen: null
  property bool active: false
  property string edge: "top"
  property int reserveSize: 0
  property string layerNamespace: "lacuna-frame-reserve"

  readonly property bool horizontal: edge === "top" || edge === "bottom"

  visible: active && reserveSize > 0
  screen: targetScreen
  color: "transparent"
  implicitWidth: horizontal ? 0 : reserveSize
  implicitHeight: horizontal ? reserveSize : 0
  // Callers may share a base namespace for one frame; the edge suffix keeps
  // each reserve layer unique when all four edges are active.
  WlrLayershell.namespace: layerNamespace + "-" + edge
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.exclusionMode: visible ? ExclusionMode.Auto : ExclusionMode.Ignore
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

  anchors {
    top: root.edge === "top" || root.edge === "left" || root.edge === "right"
    bottom: root.edge === "bottom" || root.edge === "left" || root.edge === "right"
    left: root.edge === "left" || root.edge === "top" || root.edge === "bottom"
    right: root.edge === "right" || root.edge === "top" || root.edge === "bottom"
  }

  mask: Region {}
}
