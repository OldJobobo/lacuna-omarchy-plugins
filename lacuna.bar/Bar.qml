import Quickshell
import QtQuick
import qs.Commons
import "../lacuna.menu/menu"
import "../lacuna.menu/services"

Item {
  id: root

  property string omarchyPath: ""
  property var barWidgetRegistry: null
  property var barConfig: ({})
  property var shell: null
  property var manifest: null
  property var pluginRegistry: null
  property bool lacunaFrameHost: true

  readonly property bool barHidden: omarchyBar.barItem && omarchyBar.barItem.barHidden === true
  readonly property string position: validBarPosition(barConfig && barConfig.position ? barConfig.position : "top")
  readonly property bool vertical: position === "left" || position === "right"
  readonly property int barSize: Math.round(vertical ? Style.bar.sizeVertical : Style.bar.sizeHorizontal)
  readonly property var lacunaState: resolveLacunaState()
  readonly property var lacunaSettings: lacunaState && lacunaState.data ? lacunaState.data : ({})
  readonly property var frameSettings: lacunaSettings && lacunaSettings.frame ? lacunaSettings.frame : ({})
  readonly property var sidebarSettings: lacunaSettings && lacunaSettings.sidebar ? lacunaSettings.sidebar : ({})
  readonly property string frameMode: validFrameMode(frameSettings.mode)
  readonly property bool frameEnabled: frameMode === "fullframe"
  readonly property int frameThickness: positiveInt(frameSettings.thickness, 8)
  readonly property int frameRadius: Math.max(0, positiveInt(frameSettings.radius, 14))
  readonly property bool frameShadow: frameSettings.shadow === true
  readonly property int frameShadowOffsetX: numberSetting(frameSettings.shadowOffsetX, 2)
  readonly property int frameShadowOffsetY: numberSetting(frameSettings.shadowOffsetY, 3)
  readonly property bool cornerPieces: sidebarSettings.cornerPieces !== false
  readonly property bool hostedMenuOpen: hostedMenu.menuState && hostedMenu.menuState.open === true
  readonly property bool hostedSidebarVisible: hostedMenu.sidebarSurfaceVisible === true
  readonly property real hostedSidebarOccupiedWidth: hostedSidebarVisible
    ? Math.max(0, Number(hostedMenu.panelWidth || 0) + Number(hostedMenu.surfaceRightInset || 0))
    : 0
  readonly property string lacunaBarSourceDir: manifest && manifest.__sourceDir ? String(manifest.__sourceDir) : ""
  readonly property string lacunaRepoDir: lacunaBarSourceDir.replace(/\/lacuna\.bar\/?$/, "")
  readonly property string lacunaMenuSourceDir: lacunaRepoDir ? lacunaRepoDir + "/lacuna.menu" : ""
  readonly property var hostedMenuManifest: ({
    id: "lacuna.menu",
    __sourceDir: lacunaMenuSourceDir
  })

  function resolveLacunaState() {
    if (root.shell && typeof root.shell.ensureService === "function") {
      var ensured = root.shell.ensureService("lacuna.state")
      if (ensured) return ensured
    }
    if (root.shell && typeof root.shell.serviceFor === "function") {
      var service = root.shell.serviceFor("lacuna.state")
      if (service) return service
    }
    return null
  }

  function validBarPosition(value) {
    var next = String(value || "top")
    if (next === "top" || next === "bottom" || next === "left" || next === "right") return next
    return "top"
  }

  function validFrameMode(value) {
    var next = String(value || "off")
    if (next === "off" || next === "sidebar" || next === "fullframe") return next
    return "off"
  }

  function positiveInt(value, fallback) {
    var parsed = Number(value)
    return isFinite(parsed) && parsed > 0 ? Math.round(parsed) : fallback
  }

  function numberSetting(value, fallback) {
    var parsed = Number(value)
    return isFinite(parsed) ? Math.round(parsed) : fallback
  }

  function debugBarGeometry() {
    return omarchyBar.debugBarGeometry()
  }

  function openConfigPanel() {
    return omarchyBar.openConfigPanel()
  }

  function openMenu(payloadJson) {
    hostedMenu.open(payloadJson || "{}")
    return true
  }

  function closeMenu() {
    hostedMenu.close()
    return true
  }

  function toggleMenu(payloadJson) {
    if (hostedMenuOpen) hostedMenu.close()
    else hostedMenu.open(payloadJson || "{}")
    return true
  }

  OmarchyBarAdapter {
    id: omarchyBar

    omarchyPath: root.omarchyPath
    shell: root.shell
    manifest: root.manifest
    pluginRegistry: root.pluginRegistry
    barWidgetRegistry: root.barWidgetRegistry
    barConfig: root.barConfig
  }

  Theme {
    id: barTheme
  }

  Variants {
    model: Quickshell.screens

    LacunaFrameWindow {
      required property var modelData

      targetScreen: modelData
      active: root.frameEnabled
      barPosition: root.position
      barSize: root.barSize
      frameThickness: root.frameThickness
      frameRadius: root.frameRadius
      cornerPieces: root.cornerPieces
      frameColor: barTheme.panelBackground
      leftEdgeOccupied: root.hostedSidebarVisible && hostedMenu.sidebarScreen === modelData && !hostedMenu.panelOnRight
      rightEdgeOccupied: root.hostedSidebarVisible && hostedMenu.sidebarScreen === modelData && hostedMenu.panelOnRight
      leftOccupiedWidth: root.hostedSidebarOccupiedWidth
      rightOccupiedWidth: root.hostedSidebarOccupiedWidth
      shadowEnabled: root.frameShadow
      shadowOffsetX: root.frameShadowOffsetX
      shadowOffsetY: root.frameShadowOffsetY
    }
  }

  // The full-frame paint surface is intentionally exclusion-ignored because it
  // spans the whole monitor. Add invisible one-edge layer-shell surfaces for the
  // non-bar frame edges so Hyprland shrinks the work area before applying
  // gaps_out. Lacuna's sidebar reserve compensates for the left frame reserve
  // when the sidebar is visible, so the client edge still lands on the visible
  // sidebar edge instead of frameThickness pixels to the right.
  Variants {
    model: Quickshell.screens

    Item {
      id: frameReserveScreen
      required property var modelData
      readonly property var screenData: modelData
      readonly property string screenNamespace: screenData && screenData.name
        ? String(screenData.name).replace(/[^A-Za-z0-9_-]/g, "-")
        : "screen"

      Variants {
        model: ["top", "bottom", "left", "right"]

        LacunaFrameReserveWindow {
          required property var modelData

          readonly property string edgeName: String(modelData)

          targetScreen: frameReserveScreen.screenData
          active: root.frameEnabled && edgeName !== root.position
          edge: edgeName
          reserveSize: root.frameThickness
          layerNamespace: "lacuna-bar-frame-reserve-" + frameReserveScreen.screenNamespace
        }
      }
    }
  }

  MenuWindow {
    id: hostedMenu

    omarchyPath: root.omarchyPath
    shell: root.shell
    manifest: root.hostedMenuManifest
    pluginRegistry: root.pluginRegistry
    barWidgetRegistry: root.barWidgetRegistry
    hostManaged: true
  }
}
