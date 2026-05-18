import QtQuick
import "../components"
import "../modules"
import "../services"

Column {
  id: root

  signal activated(var entry)
  signal collapseRequested()
  signal quickLaunchMoveRequested(string appId, int targetIndex)
  signal quickLaunchRenameRequested(string appId, string label)
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
  property bool quickLaunchOrderingUnlocked: false
  property bool quickLaunchContextOpen: false
  property real quickLaunchContextX: 0
  property real quickLaunchContextY: 0
  property string quickLaunchContextAppId: ""
  property string quickLaunchContextLabel: ""
  property bool quickLaunchRenameOpen: false
  property string quickLaunchRenameAppId: ""
  property string quickLaunchRenameText: ""
  property real quickLaunchRenameX: 0
  property real quickLaunchRenameY: 0
  property string draggingQuickLaunchAppId: ""
  property int quickLaunchDropIndex: -1
  property real quickLaunchDropY: 0
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

  function quickLaunchIndexForSceneY(sceneY) {
    return quickLaunchDropPositionForSceneY(sceneY).index
  }

  function quickLaunchDropPositionForSceneY(sceneY) {
    var target = 0
    var markerY = 0
    var seen = false
    var children = itemList.children

    for (var i = 0; i < children.length; i++) {
      var child = children[i]
      if (!child || !child.entry || child.entry.reorderable !== true) continue

      var center = child.mapToItem(null, 0, child.height / 2).y
      if (!seen) {
        markerY = Math.max(0, child.y - root.designTokens.itemSpacing / 2)
        seen = true
      }

      if (sceneY > center) {
        target = child.entry.quickLaunchIndex + 1
        markerY = child.y + child.height + root.designTokens.itemSpacing / 2
      }
    }

    return { index: target, y: markerY, valid: seen }
  }

  function updateQuickLaunchDrop(sceneY) {
    var position = quickLaunchDropPositionForSceneY(sceneY)
    quickLaunchDropIndex = position.valid ? position.index : -1
    quickLaunchDropY = position.y
  }

  function openQuickLaunchRename(appId, label) {
    quickLaunchRenameAppId = appId
    quickLaunchRenameText = label
    var popoverWidth = Math.min(itemList.width, root.compact ? 190 : 218)
    quickLaunchRenameX = Math.max(0, Math.min(itemList.width - popoverWidth, quickLaunchContextX))
    quickLaunchRenameY = quickLaunchContextY
    quickLaunchContextOpen = false
    quickLaunchRenameOpen = true

    Qt.callLater(function() {
      renameInput.forceActiveFocus()
      renameInput.selectAll()
    })
  }

  function saveQuickLaunchRename() {
    root.quickLaunchRenameRequested(quickLaunchRenameAppId, renameInput.text)
    quickLaunchRenameOpen = false
  }

  spacing: designTokens.sectionSpacing
  onCurrentViewChanged: {
    viewProgress = 0
    quickLaunchContextOpen = false
    quickLaunchRenameOpen = false
    draggingQuickLaunchAppId = ""
    quickLaunchDropIndex = -1
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
    id: itemFlick

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

    Item {
      id: quickLaunchDropMarker

      visible: root.draggingQuickLaunchAppId !== "" && root.quickLaunchDropIndex >= 0
      z: 24
      x: 4
      y: root.quickLaunchDropY - height / 2
      width: Math.max(0, itemList.width - 8)
      height: 8

      Behavior on y {
        LacunaAnim { motion: "fast" }
      }

      LacunaRect {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: 2
        radius: 1
        color: root.accent
        opacity: 0.88
      }

      LacunaRect {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 6
        height: 6
        radius: 3
        color: root.accent
      }

      LacunaRect {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 6
        height: 6
        radius: 3
        color: root.accent
      }
    }

    LacunaRect {
      id: quickLaunchContextMenu

      visible: root.quickLaunchContextOpen
      z: 30
      x: root.quickLaunchContextX
      y: root.quickLaunchContextY
      width: root.compact ? 106 : 118
      height: root.compact ? 56 : 62
      radius: root.designTokens.material ? 8 : root.designTokens.controlRadius
      color: root.background
      border.width: root.designTokens.carbon ? 0 : 1
      border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.28)
      clip: true

      Column {
        anchors.fill: parent
        spacing: 0

        Item {
          width: parent.width
          height: root.compact ? 28 : 31

          LacunaText {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            text: root.quickLaunchOrderingUnlocked ? "Lock order" : "Unlock order"
            color: root.foreground
            fontFamily: root.bodyFontFamily
            font.pixelSize: root.compact ? 9 : 10
            font.weight: Font.DemiBold
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
          }

          LacunaStateLayer {
            anchors.fill: parent
            stateColor: root.accent
            hoverOpacity: root.designTokens.hoverOpacity
            pressOpacity: root.designTokens.activeOpacity
            onTriggered: {
              root.quickLaunchOrderingUnlocked = !root.quickLaunchOrderingUnlocked
              root.quickLaunchContextOpen = false
            }
          }
        }

        Item {
          width: parent.width
          height: root.compact ? 28 : 31

          LacunaRect {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 1
            color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08)
          }

          LacunaText {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            text: "Rename"
            color: root.foreground
            fontFamily: root.bodyFontFamily
            font.pixelSize: root.compact ? 9 : 10
            font.weight: Font.DemiBold
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
          }

          LacunaStateLayer {
            anchors.fill: parent
            stateColor: root.accent
            hoverOpacity: root.designTokens.hoverOpacity
            pressOpacity: root.designTokens.activeOpacity
            onTriggered: root.openQuickLaunchRename(root.quickLaunchContextAppId, root.quickLaunchContextLabel)
          }
        }
      }
    }

    LacunaRect {
      id: quickLaunchRenamePopover

      visible: root.quickLaunchRenameOpen
      z: 31
      x: root.quickLaunchRenameX
      y: root.quickLaunchRenameY
      width: Math.min(itemList.width, root.compact ? 190 : 218)
      height: root.compact ? 34 : 38
      radius: root.designTokens.material ? 9 : root.designTokens.controlRadius
      color: root.background
      border.width: root.designTokens.carbon ? 0 : 1
      border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.34)
      clip: true

      TextInput {
        id: renameInput

        anchors.left: parent.left
        anchors.right: saveRenameButton.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 10
        anchors.rightMargin: 6
        height: parent.height
        text: root.quickLaunchRenameText
        color: root.foreground
        selectionColor: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.36)
        selectedTextColor: root.foreground
        font.family: root.bodyFontFamily
        font.pixelSize: root.compact ? 10 : 11
        verticalAlignment: TextInput.AlignVCenter
        selectByMouse: true
        clip: true
        onTextChanged: root.quickLaunchRenameText = text
        Keys.onReturnPressed: root.saveQuickLaunchRename()
        Keys.onEnterPressed: root.saveQuickLaunchRename()
        Keys.onEscapePressed: root.quickLaunchRenameOpen = false
      }

      LacunaIconButton {
        id: saveRenameButton

        anchors.right: cancelRenameButton.left
        anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        icon: "check"
        foreground: root.foreground
        muted: root.muted
        accent: root.accent
        buttonSize: root.compact ? 22 : 24
        iconSize: root.compact ? 12 : 13
        buttonRadius: root.designTokens.controlRadius
        hoverOpacity: root.designTokens.hoverOpacity
        pressOpacity: root.designTokens.activeOpacity
        fontFamily: root.bodyFontFamily
        onTriggered: root.saveQuickLaunchRename()
      }

      LacunaIconButton {
        id: cancelRenameButton

        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        icon: "x"
        foreground: root.foreground
        muted: root.muted
        accent: root.dangerAccent
        buttonSize: root.compact ? 22 : 24
        iconSize: root.compact ? 12 : 13
        buttonRadius: root.designTokens.controlRadius
        hoverOpacity: root.designTokens.hoverOpacity
        pressOpacity: root.designTokens.activeOpacity
        fontFamily: root.bodyFontFamily
        onTriggered: root.quickLaunchRenameOpen = false
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
        designTokens: root.designTokens
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
        reorderHandleVisible: root.quickLaunchOrderingUnlocked && parent.entry.reorderable === true
        reorderActive: root.draggingQuickLaunchAppId !== "" && root.draggingQuickLaunchAppId === parent.entry.appId
        optionValue: parent.entry.optionValue || ""
        options: parent.entry.options || []
        background: root.background
        fontFamily: root.bodyFontFamily
        labelFontFamily: root.itemFontFamily
        iconRailWidth: root.iconRailWidth
        compact: root.compact
        designTokens: root.designTokens
        onTriggered: root.activated(parent.entry)
        onContextRequested: function(x, y) {
          if (parent.entry.reorderable !== true) return
          var point = parent.mapToItem(itemList, x, y)
          root.quickLaunchContextAppId = parent.entry.appId
          root.quickLaunchContextLabel = parent.entry.label
          root.quickLaunchRenameOpen = false
          root.quickLaunchContextX = Math.max(0, Math.min(itemList.width - quickLaunchContextMenu.width, point.x))
          root.quickLaunchContextY = Math.max(0, point.y)
          root.quickLaunchContextOpen = true
        }
        onReorderDragStarted: function(sceneY) {
          if (parent.entry.reorderable !== true) return
          root.draggingQuickLaunchAppId = parent.entry.appId
          root.updateQuickLaunchDrop(sceneY)
        }
        onReorderDragged: function(sceneY) {
          if (parent.entry.reorderable !== true) return
          root.updateQuickLaunchDrop(sceneY)
        }
        onReorderDropped: function(sceneY) {
          if (parent.entry.reorderable !== true) return
          var targetIndex = root.quickLaunchDropIndex >= 0 ? root.quickLaunchDropIndex : root.quickLaunchIndexForSceneY(sceneY)
          root.draggingQuickLaunchAppId = ""
          root.quickLaunchDropIndex = -1
          root.quickLaunchMoveRequested(parent.entry.appId, targetIndex)
        }
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
