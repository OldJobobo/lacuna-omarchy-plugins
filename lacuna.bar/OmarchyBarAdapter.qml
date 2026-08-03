import QtQuick

Item {
  id: root

  required property string omarchyPath
  required property var barWidgetRegistry
  required property var barConfig
  property var shell: null
  property var manifest: null
  property var pluginRegistry: null
  property var menuToggleHandler: null
  property bool portraitSplitEnabled: true
  property bool frameBorderEnabled: false
  property bool barOutlineEnabled: false
  property var barOutlineInsetsProvider: null
  property var popoutAvoidanceInsetsProvider: null
  property var fullscreenSuppressionProvider: null
  property color frameBorderColor: "transparent"
  readonly property var barItem: omarchyBar

  function debugBarGeometry() {
    return omarchyBar.debugBarGeometry()
  }

  function openConfigPanel() {
    return omarchyBar.openConfigPanel()
  }

  function summonBarWidget(pluginId) {
    return omarchyBar.summonBarWidget(pluginId)
  }

  function hideBarWidget(pluginId) {
    return omarchyBar.hideBarWidget(pluginId)
  }

  function isBarWidgetOpen(pluginId) {
    return omarchyBar.isBarWidgetOpen(pluginId)
  }

  OmarchyBar {
    id: omarchyBar

    omarchyPath: root.omarchyPath
    barWidgetRegistry: root.barWidgetRegistry
    barConfig: root.barConfig
    shell: root.shell
    manifest: root.manifest
    menuToggleHandler: root.menuToggleHandler
    portraitSplitEnabled: root.portraitSplitEnabled
    frameBorderEnabled: root.frameBorderEnabled
    barOutlineEnabled: root.barOutlineEnabled
    barOutlineInsetsProvider: root.barOutlineInsetsProvider
    popoutAvoidanceInsetsProvider: root.popoutAvoidanceInsetsProvider
    fullscreenSuppressionProvider: root.fullscreenSuppressionProvider
    frameBorderColor: root.frameBorderColor
  }
}
