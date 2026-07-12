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
  readonly property var barItem: omarchyBar

  function debugBarGeometry() {
    return omarchyBar.debugBarGeometry()
  }

  function openConfigPanel() {
    return omarchyBar.openConfigPanel()
  }

  OmarchyBar {
    id: omarchyBar

    omarchyPath: root.omarchyPath
    barWidgetRegistry: root.barWidgetRegistry
    barConfig: root.barConfig
    shell: root.shell
    manifest: root.manifest
    menuToggleHandler: root.menuToggleHandler
  }
}
