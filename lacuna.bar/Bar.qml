import Quickshell
import QtQuick
import qs.Commons
import "../lacuna.menu/menu"
import "../lacuna.menu/services"
import "ScreenModel.js" as ScreenModel

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
  readonly property bool frameBorder: frameSettings.border === true
  readonly property int frameShadowOffsetX: numberSetting(frameSettings.shadowOffsetX, 2)
  readonly property int frameShadowOffsetY: numberSetting(frameSettings.shadowOffsetY, 3)
  readonly property bool cornerPieces: sidebarSettings.cornerPieces !== false
  readonly property bool hostedMenuOpen: hostedMenu.menuState && hostedMenu.menuState.open === true
  readonly property bool hostedSidebarVisible: hostedMenu.sidebarSurfaceVisible === true
  readonly property bool hostedSidebarOnLeft: hostedSidebarVisible && !hostedMenu.panelOnRight
  readonly property bool hostedSidebarOnRight: hostedSidebarVisible && hostedMenu.panelOnRight
  // The full-frame cutout is cast from the visible sidebar body edge.
  // The molding inset belongs to the sidebar join; including it here pushes
  // the cutout and shadow past the actual frame edge.
  readonly property real hostedSidebarFrameOcclusionWidth: hostedSidebarVisible
    ? Math.max(0, Number(hostedMenu.panelWidth || 0))
    : 0
  readonly property string lacunaFrameGeometryKey: [
    frameMode,
    frameThickness,
    frameRadius,
    cornerPieces,
    position,
    barSize,
    hostedSidebarVisible,
    hostedSidebarFrameOcclusionWidth,
    hostedMenu.panelOnRight,
    hostedMenu.sidebarScreen ? String(hostedMenu.sidebarScreen.name || "") : ""
  ].join("|")
  readonly property string lacunaBarSourceDir: manifest && manifest.__sourceDir ? String(manifest.__sourceDir) : ""
  readonly property string lacunaRepoDir: lacunaBarSourceDir.replace(/\/lacuna\.bar\/?$/, "")
  readonly property string lacunaMenuSourceDir: lacunaRepoDir ? lacunaRepoDir + "/lacuna.menu" : ""
  readonly property var hostedMenuManifest: ({
    id: "lacuna.menu",
    __sourceDir: lacunaMenuSourceDir
  })
  readonly property var validBarScreens: ScreenModel.validScreens(Quickshell.screens)

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

  function hostedSidebarOccupiesEdge(edge, screen) {
    if (!hostedSidebarVisibleOnScreen(screen)) return false
    return (edge === "left" && hostedSidebarOnLeft) || (edge === "right" && hostedSidebarOnRight)
  }

  function hostedSidebarVisibleOnScreen(screen) {
    if (!hostedSidebarVisible) return false
    if (hostedMenu && typeof hostedMenu.sidebarVisibleOnScreen === "function") {
      return hostedMenu.sidebarVisibleOnScreen(screen)
    }
    return hostedMenu.sidebarScreen === screen
  }

  function hostedFlyoutVisibleOnScreen(screen) {
    if (!hostedSidebarVisibleOnScreen(screen)) return false
    if (hostedMenu && typeof hostedMenu.frameBorderAttachedFlyoutVisibleOnScreen === "function") {
      return hostedMenu.frameBorderAttachedFlyoutVisibleOnScreen(screen)
    }
    return hostedMenu.frameBorderAttachedFlyoutVisible === true
  }

  function lacunaFrameContentRect(screen) {
    var screenWidth = screen && screen.width !== undefined ? Number(screen.width) : 0
    var screenHeight = screen && screen.height !== undefined ? Number(screen.height) : 0
    var t = Math.max(1, root.frameThickness)
    var topInset = root.position === "top" ? Math.max(0, root.barSize) : t
    var bottomInset = root.position === "bottom" ? Math.max(0, root.barSize) : t
    var leftInset = root.position === "left" ? Math.max(0, root.barSize) : t
    var rightInset = root.position === "right" ? Math.max(0, root.barSize) : t
    var sidebarOnThisScreen = root.hostedSidebarVisibleOnScreen(screen)
    var leftOcclusion = sidebarOnThisScreen && !hostedMenu.panelOnRight ? root.hostedSidebarFrameOcclusionWidth : 0
    var rightOcclusion = sidebarOnThisScreen && hostedMenu.panelOnRight ? root.hostedSidebarFrameOcclusionWidth : 0
    var x = Math.max(0, leftOcclusion > 0 ? leftOcclusion : leftInset)
    var y = Math.max(0, topInset)
    var right = Math.max(x + 1, screenWidth - (rightOcclusion > 0 ? rightOcclusion : rightInset))
    var bottom = Math.max(y + 1, screenHeight - bottomInset)
    var bleed = root.frameEnabled ? Math.max(t + 2, Math.ceil(root.frameRadius * 0.5)) : 0

    if (!root.frameEnabled || screenWidth <= 0 || screenHeight <= 0) {
      return {
        x: 0,
        y: 0,
        width: Math.max(1, screenWidth),
        height: Math.max(1, screenHeight),
        radius: 0,
        bleed: 0,
        framed: false
      }
    }

    return {
      x: Math.max(0, x - bleed),
      y: Math.max(0, y - bleed),
      width: Math.max(1, Math.min(screenWidth, right + bleed) - Math.max(0, x - bleed)),
      height: Math.max(1, Math.min(screenHeight, bottom + bleed) - Math.max(0, y - bleed)),
      radius: root.cornerPieces ? Math.max(t, root.frameRadius) : 0,
      bleed: bleed,
      framed: true,
      innerX: x,
      innerY: y,
      innerWidth: Math.max(1, right - x),
      innerHeight: Math.max(1, bottom - y)
    }
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

  function contextualMenuPayload(payloadJson, popupContext) {
    var payload = {}
    try {
      var parsed = JSON.parse(String(payloadJson || "{}"))
      if (parsed && typeof parsed === "object") payload = parsed
    } catch (e) {
    }
    payload.popupContext = popupContext || ({})
    return JSON.stringify(payload)
  }

  Theme {
    id: barTheme
  }

  // Declaration order is mapping order, and within a Wayland layer stacking
  // is mapping order: the always-mapped frame surfaces must be created
  // before the bar (and the hosted menu below) so the bar and sidebar
  // render above the frame paint.
  Variants {
    model: root.validBarScreens

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
      shadowEnabled: root.frameShadow
      shadowOffsetX: root.frameShadowOffsetX
      shadowOffsetY: root.frameShadowOffsetY
      leftEdgeOccupied: root.hostedSidebarVisibleOnScreen(modelData) && !hostedMenu.panelOnRight
      rightEdgeOccupied: root.hostedSidebarVisibleOnScreen(modelData) && hostedMenu.panelOnRight
      leftOccupiedWidth: root.hostedSidebarFrameOcclusionWidth
      rightOccupiedWidth: root.hostedSidebarFrameOcclusionWidth
    }
  }

  Variants {
    model: root.validBarScreens

    LacunaFrameBorderWindow {
      required property var modelData

      targetScreen: modelData
      active: root.frameEnabled && root.frameBorder
      barPosition: root.position
      barSize: root.barSize
      frameThickness: root.frameThickness
      frameRadius: root.frameRadius
      cornerPieces: root.cornerPieces
      borderColor: barTheme.seam
      leftEdgeOccupied: root.hostedSidebarVisibleOnScreen(modelData) && !hostedMenu.panelOnRight
      rightEdgeOccupied: root.hostedSidebarVisibleOnScreen(modelData) && hostedMenu.panelOnRight
      leftOccupiedWidth: root.hostedSidebarFrameOcclusionWidth
      rightOccupiedWidth: root.hostedSidebarFrameOcclusionWidth
      attachedFlyoutVisible: root.hostedFlyoutVisibleOnScreen(modelData)
      attachedFlyoutY: hostedMenu.frameBorderAttachedFlyoutYFor ? hostedMenu.frameBorderAttachedFlyoutYFor(modelData) : hostedMenu.frameBorderAttachedFlyoutY
      attachedFlyoutHeight: hostedMenu.frameBorderAttachedFlyoutHeightFor ? hostedMenu.frameBorderAttachedFlyoutHeightFor(modelData) : hostedMenu.frameBorderAttachedFlyoutHeight
    }
  }

  OmarchyBarAdapter {
    id: omarchyBar

    omarchyPath: root.omarchyPath
    shell: root.shell
    manifest: root.manifest
    pluginRegistry: root.pluginRegistry
    barWidgetRegistry: root.barWidgetRegistry
    barConfig: root.barConfig
    menuToggleHandler: function(payloadJson, popupContext) {
      return root.toggleMenu(root.contextualMenuPayload(payloadJson, popupContext))
    }
  }

  // The full-frame paint surface is intentionally exclusion-ignored because it
  // spans the whole monitor. Add invisible one-edge layer-shell surfaces for
  // non-bar frame edges so Hyprland shrinks the work area before applying
  // gaps_out. When the hosted sidebar occupies an edge, that sidebar's own
  // reserve owns the workarea there; keeping an extra frame reserve would leave
  // a visible frameThickness gap at the bar end.
  // Frame reserve exclusive zones must never be arranged before the bar
  // windows: at shell start with fullframe already enabled the reserves are
  // created first (the vendored bar maps on its own schedule) and their
  // zones inset the bar itself — seen live as a frameThickness-wide
  // background gap at the bar's outer corner on every monitor. Reserves
  // therefore activate only after a startup settle window, so they always
  // arrange after the bars; runtime frame toggles are unaffected.
  property bool frameReservesReady: false

  Timer {
    id: frameReserveSettleTimer
    interval: 1200
    running: true
    repeat: false
    onTriggered: root.frameReservesReady = true
  }

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
          active: root.frameEnabled
            && root.frameReservesReady
            && edgeName !== root.position
            && !root.hostedSidebarOccupiesEdge(edgeName, frameReserveScreen.screenData)
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
    hostBarSize: root.barSize
  }
}
