import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import "../services"
import "../components"

Item {
  id: root

  property string omarchyPath: ""
  property var shell: null
  property var manifest: null
  property var pluginRegistry: null
  property string pluginId: manifest && manifest.id ? manifest.id : "omarchy.lacuna-menu"
  property var menuState: localMenuState
  property string lacunaPath: manifest && manifest.__sourceDir ? manifest.__sourceDir : localPath(Qt.resolvedUrl(".."))
  property var sharedCompactState: null
  property var sharedSidebarState: null
  property bool hostClosing: false
  readonly property var compactState: sharedCompactState || localCompactState
  readonly property var sidebarState: sharedSidebarState || localSidebarState
  property color foreground: menuTheme.foreground
  property color background: menuTheme.background
  property color panelColor: menuTheme.background
  property color accent: menuTheme.accent
  property color shellAccent: menuTheme.color("color6")
  property color sessionAccent: menuTheme.color("color11")
  property color dangerAccent: menuTheme.color("color9")
  property color navAccent: menuTheme.soft
  property color muted: menuTheme.muted
  property string version: ""
  property bool compact: compactState.compact
  property bool forceCompactRail: false
  property bool railCompact: forceCompactRail ? true : compact
  property string designStyle: lacunaSettings.data && lacunaSettings.data.designStyle ? lacunaSettings.data.designStyle : "carbon"
  property int fullPanelWidth: compact ? 270 : 310
  property int railButtonWidth: railCompact ? 24 : barHeight
  property int railLeftInset: railDesignTokens.railLeftInset
  property int railRightInset: railDesignTokens.railRightInset
  property int railPanelWidth: railButtonWidth + railLeftInset + railRightInset
  property int panelWidth: sidebarState.collapsed ? railPanelWidth : fullPanelWidth
  property int defaultTopBarHeight: 26
  property int barHeight: topBarHeight()
  property int joinRadius: sidebarState.cornerPieces ? (compact ? 14 : 18) : 0
  property int connectorOverlap: sidebarState.cornerPieces ? (compact ? 25 : 33) : 0
  property int bodyRightInset: sidebarState.cornerPieces ? joinRadius : 0
  property int surfaceRightInset: bodyRightInset
  // In exclusive mode the compositor already places this window below the top
  // bar, so the bar edge is local y=0. In overlay mode the window starts at
  // screen top and the bar edge is the live bar height.
  property int barBottomY: sidebarState.exclusive ? 0 : barHeight
  property bool panelVisible: menuState.open
  property bool quickLaunchPickerOpen: false
  property string quickLaunchPickerMode: "quickLaunch"
  property string appDefaultPickerRole: ""
  property int quickLaunchPickerWidth: compact ? 260 : 300
  readonly property var sidebarScreen: Quickshell.screens && Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

  function localPath(url) {
    var value = String(url || "")
    if (value.indexOf("file://") === 0) value = value.slice(7)
    return decodeURIComponent(value)
  }

  function positiveInt(value, fallback) {
    var parsed = Number(value)
    return isFinite(parsed) && parsed > 0 ? Math.round(parsed) : fallback
  }

  function configBarHeight() {
    var barConfig = shell && shell.barConfig ? shell.barConfig : null
    if (!barConfig || typeof barConfig !== "object") return defaultTopBarHeight
    return positiveInt(barConfig.height !== undefined ? barConfig.height : barConfig.size, defaultTopBarHeight)
  }

  function topBarHeight() {
    var liveBar = shell && shell.bar ? shell.bar : null
    var livePosition = liveBar && liveBar.position ? String(liveBar.position) : ""
    var configPosition = shell && shell.barConfig && shell.barConfig.position ? String(shell.barConfig.position) : "top"
    var position = livePosition || configPosition

    if (position !== "top") return 0
    if (liveBar && !liveBar.barHidden && liveBar.barSize !== undefined) {
      return positiveInt(liveBar.barSize, configBarHeight())
    }
    return configBarHeight()
  }

  function open(payloadJson) {
    hostClosing = false
    menuState.show()
  }

  function close() {
    hostClosing = true
    menuState.close()
    panelVisible = false
    hostClosing = false
  }

  function viewToneAccent() {
    if (menuState.currentView === "system") return root.dangerAccent
    if (menuState.currentView === "lacuna-shell") return root.shellAccent
    if (menuState.currentView === "lacuna" || menuState.currentView === "lacuna-preferences") return root.accent
    return root.accent
  }

  function setDesignStyle(style) {
    var nextStyleSettings = lacunaSettings.normalize(lacunaSettings.data)
    nextStyleSettings.designStyle = lacunaSettings.normalizeDesignStyle(style)
    lacunaSettings.save(nextStyleSettings)
  }

  function quickLaunchContains(id) {
    var ids = lacunaSettings.data && lacunaSettings.data.quickLaunch ? lacunaSettings.data.quickLaunch : []
    for (var i = 0; i < ids.length; i++) {
      if (String(ids[i]) === String(id)) return true
    }
    return false
  }

  function addQuickLaunchApp(id) {
    if (!id || quickLaunchContains(id)) return

    var next = lacunaSettings.normalize(lacunaSettings.data)
    next.quickLaunch = next.quickLaunch.concat([String(id)]).slice(0, 12)
    lacunaSettings.save(next)
  }

  function appDefaultValue(role) {
    var defaults = lacunaSettings.data && lacunaSettings.data.appDefaults ? lacunaSettings.data.appDefaults : {}
    var value = String(defaults[role] || "").trim()
    return value === "" ? "system" : value
  }

  function setAppDefault(role, id) {
    if (!role) return

    var next = lacunaSettings.normalize(lacunaSettings.data)
    next.appDefaults[role] = String(id || "system").trim() || "system"
    lacunaSettings.save(next)
    quickLaunchPickerOpen = false
  }

  function openQuickLaunchPicker() {
    if (!appCatalog.ready) appCatalog.reload()
    quickLaunchPickerMode = "quickLaunch"
    appDefaultPickerRole = ""
    quickLaunchPickerOpen = true
    if (sidebarState.collapsed) sidebarState.expand()
    Qt.callLater(function() {
      searchInput.forceActiveFocus()
    })
  }

  function openAppDefaultPicker(role) {
    if (!appCatalog.ready) appCatalog.reload()
    quickLaunchPickerMode = "appDefault"
    appDefaultPickerRole = role
    quickLaunchPickerOpen = true
    if (sidebarState.collapsed) sidebarState.expand()
    Qt.callLater(function() {
      searchInput.forceActiveFocus()
    })
  }

  function activate(entry) {
    if (!entry || entry.kind === "header") return

    if (entry.action === "toggle-sidebar-mode") {
      sidebarState.toggle()
      return
    }

    if (entry.action === "toggle-sidebar-rail") {
      sidebarState.toggleCollapsed()
      return
    }

    if (entry.action === "toggle-corner-pieces") {
      sidebarState.toggleCornerPieces()
      return
    }

    if (entry.action === "toggle-bar-density") {
      compactState.toggle()
      return
    }

    if (entry.action === "open-quicklaunch-picker") {
      openQuickLaunchPicker()
      return
    }

    if (entry.action === "add-quicklaunch") {
      addQuickLaunchApp(entry.appId)
      return
    }

    if (entry.action === "toggle-color-profile") {
      var next = lacunaSettings.normalize(lacunaSettings.data)
      next.colorProfile = next.colorProfile === "colorful" ? "semantic" : "colorful"
      lacunaSettings.save(next)
      return
    }

    if (entry.action === "cycle-design-style") {
      var nextStyleSettings = lacunaSettings.normalize(lacunaSettings.data)
      nextStyleSettings.designStyle = lacunaSettings.nextDesignStyle(nextStyleSettings.designStyle)
      lacunaSettings.save(nextStyleSettings)
      return
    }

    if (entry.action.indexOf("set-design-style-") === 0) {
      setDesignStyle(entry.action.substring("set-design-style-".length))
      return
    }

    if (entry.action.indexOf("choose-app-default-") === 0) {
      openAppDefaultPicker(entry.action.substring("choose-app-default-".length))
      return
    }

    if (entry.action === "reload-apps") {
      appCatalog.reload()
      return
    }

    if (entry.action === "open-screenrecord-menu") {
      menuState.close()
      commands.run("omarchy-capture-screenrecording --stop-recording || omarchy-shell-ipc menu summon trigger.capture.screenrecord")
      return
    }

    if (entry.view) {
      if (sidebarState.collapsed) sidebarState.expand()
      quickLaunchPickerOpen = false
      menuState.push(entry.view)
      return
    }

    if (entry.command) {
      quickLaunchPickerOpen = false
      commands.run(entry.command)
    }
  }

  Component.onCompleted: versionFile.reload()

  LacunaMenuState {
    id: localMenuState
  }

  LacunaSettings {
    id: lacunaSettings
  }

  CompactState {
    id: localCompactState
    settingsService: lacunaSettings
  }

  SidebarState {
    id: localSidebarState
    settingsService: lacunaSettings
  }

  AppCatalog {
    id: appCatalog
    lacunaPath: root.lacunaPath
  }

  Theme {
    id: menuTheme
  }

  DesignTokens {
    id: designTokens
    designStyle: root.designStyle
    compact: root.compact
    foreground: root.foreground
    background: root.background
    accent: root.accent
  }

  DesignTokens {
    id: railDesignTokens
    designStyle: root.designStyle
    compact: root.railCompact
    foreground: root.foreground
    background: root.background
    accent: root.accent
  }

  FileView {
    id: versionFile

    path: root.lacunaPath + "/VERSION"
    watchChanges: true
    printErrors: false
    onLoaded: {
      var raw = text().trim()
      root.version = raw === "" ? "" : "v" + raw.replace(/^v/, "")
    }
    onFileChanged: reload()
  }

  MenuRegistry {
    id: registry
    lacunaPath: root.lacunaPath
    sidebarExclusive: sidebarState.exclusive
    sidebarCollapsed: sidebarState.collapsed
    sidebarCornerPieces: sidebarState.cornerPieces
    compact: root.compact
    designStyle: root.designStyle
    colorProfile: lacunaSettings.data && lacunaSettings.data.colorProfile ? lacunaSettings.data.colorProfile : "semantic"
    appCatalog: appCatalog
    quickLaunch: lacunaSettings.data && lacunaSettings.data.quickLaunch ? lacunaSettings.data.quickLaunch : []
    appDefaults: lacunaSettings.data && lacunaSettings.data.appDefaults ? lacunaSettings.data.appDefaults : ({})
  }

  Connections {
    target: root.menuState
    function onOpenChanged() {
      if (root.menuState.open) {
        root.panelVisible = true
      } else {
        root.quickLaunchPickerOpen = false
        hideTimer.restart()
        if (!root.hostClosing && root.shell && root.shell.hide) {
          root.shell.hide(root.pluginId)
        }
      }
    }
  }

  Timer {
    id: hideTimer
    interval: 190
    repeat: false
    onTriggered: if (!root.menuState.open) root.panelVisible = false
  }

  CommandRunner {
    id: commands
  }

  PanelWindow {
    id: menuWindow

    visible: root.panelVisible
    screen: root.sidebarScreen
    color: "transparent"
    implicitWidth: root.panelWidth + root.surfaceRightInset + (root.quickLaunchPickerOpen ? root.quickLaunchPickerWidth + 12 : 0)
    exclusiveZone: sidebarState.exclusive && root.menuState.open ? root.panelWidth : 0
    exclusionMode: sidebarState.exclusive ? ExclusionMode.Normal : ExclusionMode.Ignore
    WlrLayershell.namespace: "lacuna-menu"
    WlrLayershell.layer: sidebarState.exclusive ? WlrLayer.Top : WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.quickLaunchPickerOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors {
      top: true
      bottom: true
      left: true
    }

    MenuSurface {
      id: surface

      anchors.top: parent.top
      anchors.bottom: parent.bottom
      panelWidth: root.panelWidth
      open: root.menuState.open
      barHeight: root.barHeight
      barBottomY: root.barBottomY
      joinRadius: root.joinRadius
      connectorOverlap: root.connectorOverlap
      bodyRightInset: root.surfaceRightInset
      cornerPieces: sidebarState.cornerPieces
      panelColor: root.panelColor
      foreground: root.foreground
      designTokens: designTokens

      MenuContent {
        visible: !sidebarState.collapsed
        anchors.fill: parent
        anchors.leftMargin: designTokens.contentInset
        anchors.rightMargin: designTokens.contentInset
        anchors.topMargin: root.barBottomY + designTokens.topInset
        anchors.bottomMargin: designTokens.bottomInset
        compact: root.compact
        designTokens: designTokens
        open: root.menuState.open
        menuState: root.menuState
        registry: registry
        version: root.version
        themeTitle: menuTheme.themeTitle
        foreground: root.foreground
        background: root.background
        accent: root.accent
        shellAccent: root.shellAccent
        sessionAccent: root.sessionAccent
        dangerAccent: root.dangerAccent
        navAccent: root.navAccent
        muted: root.muted
        iconRailWidth: root.barHeight
        onActivated: function(entry) {
          root.activate(entry)
        }
        onCollapseRequested: sidebarState.toggleCollapsed()
      }

      MenuRail {
        visible: sidebarState.collapsed
        anchors.top: parent.top
        anchors.topMargin: root.barBottomY + (root.railCompact ? 6 : 10)
        anchors.left: parent.left
        anchors.leftMargin: root.railLeftInset
        compact: root.railCompact
        designTokens: railDesignTokens
        open: root.menuState.open
        menuState: root.menuState
        registry: registry
        foreground: root.foreground
        panelWindow: menuWindow
        panelColor: root.panelColor
        accent: root.accent
        shellAccent: root.shellAccent
        sessionAccent: root.sessionAccent
        dangerAccent: root.dangerAccent
        navAccent: root.navAccent
        muted: root.muted
        railWidth: root.railButtonWidth
        onExpandRequested: sidebarState.toggleCollapsed()
        onCompactToggleRequested: compactState.toggle()
        onActivated: function(entry) {
          root.activate(entry)
        }
      }
    }

    LacunaRect {
      id: quickLaunchPicker

      property string query: ""

      function filteredApps() {
        var apps = appCatalog.apps || []
        var needle = query.toLowerCase().trim()
        var list = []

        for (var i = 0; i < apps.length; i++) {
          var app = apps[i]
          var haystack = String((app.Name || "") + " " + (app.GenericName || "") + " " + (app.Comment || "") + " " + (app.Categories || "")).toLowerCase()
          if (needle === "" || haystack.indexOf(needle) >= 0) list.push(app)
          if (list.length >= 80) break
        }

        return list
      }

      visible: root.menuState.open && root.quickLaunchPickerOpen
      enabled: root.quickLaunchPickerOpen
      opacity: root.quickLaunchPickerOpen ? 1 : 0
      x: root.panelWidth + root.surfaceRightInset + 8
      y: root.barBottomY + designTokens.topInset
      width: root.quickLaunchPickerWidth
      height: Math.min(menuWindow.height - y - designTokens.bottomInset, root.compact ? 430 : 520)
      radius: designTokens.material ? designTokens.radius : 0
      color: root.panelColor
      border.width: designTokens.borderWidth
      border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.28)
      clip: true

      Behavior on opacity {
        LacunaAnim { motion: "fast" }
      }

      Column {
        anchors.fill: parent
        anchors.margins: root.compact ? 10 : 12
        spacing: root.compact ? 8 : 10

        Row {
          width: parent.width
          height: root.compact ? 26 : 30
          spacing: 8

          LacunaText {
            width: parent.width - closePicker.width - parent.spacing
            anchors.verticalCenter: parent.verticalCenter
            text: root.quickLaunchPickerMode === "appDefault" ? "Set " + registry.roleMeta(root.appDefaultPickerRole).label : "Add Quick Launch"
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
            buttonRadius: designTokens.controlRadius
            hoverOpacity: designTokens.hoverOpacity
            pressOpacity: designTokens.activeOpacity
            iconSize: root.compact ? 13 : 15
            onTriggered: root.quickLaunchPickerOpen = false
          }
        }

        LacunaRect {
          width: parent.width
          height: root.compact ? 28 : 32
          radius: designTokens.material ? height / 2 : designTokens.controlRadius
          color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.07)
          border.width: 1
          border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.14)

          LacunaText {
            visible: searchInput.text === ""
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: root.quickLaunchPickerMode === "appDefault" ? "Search app override" : "Search apps"
            color: root.muted
            fontFamily: "JetBrains Mono"
            font.pixelSize: root.compact ? 10 : 11
          }

          TextInput {
            id: searchInput

            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            focus: root.quickLaunchPickerOpen
            activeFocusOnPress: true
            color: root.foreground
            selectedTextColor: root.background
            selectionColor: root.accent
            font.family: "JetBrains Mono"
            font.pixelSize: root.compact ? 10 : 11
            verticalAlignment: TextInput.AlignVCenter
            clip: true
            onTextChanged: quickLaunchPicker.query = text
          }
        }

        Flickable {
          id: appPickerFlick

          width: parent.width
          height: Math.max(0, parent.height - y)
          contentWidth: width
          contentHeight: appPickerList.implicitHeight
          clip: true
          boundsBehavior: Flickable.StopAtBounds
          flickableDirection: Flickable.VerticalFlick
          interactive: true
          ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

          function scrollBy(delta) {
            contentY = Math.max(0, Math.min(contentHeight - height, contentY - delta))
          }

          Column {
            id: appPickerList

            width: parent.width
            spacing: root.compact ? 4 : 5

            LacunaRect {
              visible: root.quickLaunchPickerMode === "appDefault"
              width: parent.width
              height: visible ? (root.compact ? 32 : 38) : 0
              radius: designTokens.radius
              color: systemPickerMouse.containsMouse ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.10) : "transparent"
              border.width: root.appDefaultValue(root.appDefaultPickerRole) === "system" && !designTokens.carbon ? 1 : 0
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
                text: registry.roleMeta(root.appDefaultPickerRole).systemHint
                color: root.foreground
                fontFamily: "JetBrains Mono"
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
                  visible: root.appDefaultValue(root.appDefaultPickerRole) === "system"
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
                hoverOpacity: designTokens.hoverOpacity
                pressOpacity: designTokens.activeOpacity
                onTriggered: root.setAppDefault(root.appDefaultPickerRole, "system")
                onScrolled: function(delta) {
                  appPickerFlick.scrollBy(delta)
                }
              }
            }

            Repeater {
              model: root.quickLaunchPickerOpen ? quickLaunchPicker.filteredApps() : []

              LacunaRect {
                required property var modelData

                readonly property bool alreadyAdded: root.quickLaunchPickerMode === "quickLaunch" && root.quickLaunchContains(modelData.id)
                readonly property bool selectedOverride: root.quickLaunchPickerMode === "appDefault" && root.appDefaultValue(root.appDefaultPickerRole) === String(modelData.id)
                width: parent.width
                height: root.compact ? 32 : 38
                radius: designTokens.radius
                color: pickerMouse.containsMouse ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.10) : "transparent"
                border.width: (alreadyAdded || selectedOverride) && !designTokens.carbon ? 1 : 0
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
                  source: registry.appIconSource(modelData)
                  visible: source !== "" && status !== Image.Error
                }

                LacunaTablerIcon {
                  anchors.centerIn: pickerIcon
                  visible: pickerIcon.source === "" || pickerIcon.status === Image.Error
                  name: registry.appIcon(modelData)
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
                  fontFamily: "JetBrains Mono"
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
                    visible: alreadyAdded || selectedOverride || root.quickLaunchPickerMode === "quickLaunch"
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
                  hoverOpacity: designTokens.hoverOpacity
                  pressOpacity: designTokens.activeOpacity
                  onTriggered: {
                    if (root.quickLaunchPickerMode === "appDefault") root.setAppDefault(root.appDefaultPickerRole, modelData.id)
                    else root.addQuickLaunchApp(modelData.id)
                  }
                  onScrolled: function(delta) {
                    appPickerFlick.scrollBy(delta)
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
