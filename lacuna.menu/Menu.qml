import QtQuick
import "menu"

Item {
  id: root

  property string omarchyPath: ""
  property var shell: null
  property var manifest: null
  property var pluginRegistry: null
  property var barWidgetRegistry: null
  property bool opened: barHostAvailable
    ? (shell && shell.bar && shell.bar.hostedMenuOpen === true)
    : (fallbackLoader.item && fallbackLoader.item.menuState && fallbackLoader.item.menuState.open === true)

  readonly property bool barHostAvailable: shell
    && shell.bar
    && shell.bar.lacunaFrameHost === true
    && typeof shell.bar.openMenu === "function"
    && typeof shell.bar.closeMenu === "function"

  function ensureFallback() {
    if (barHostAvailable) {
      unloadFallback()
      return null
    }
    fallbackLoader.active = true
    return fallbackLoader.item
  }

  function unloadFallback() {
    var item = fallbackLoader.item
    if (item && typeof item.close === "function") item.close()
    fallbackLoader.active = false
  }

  function configureFallback() {
    var item = fallbackLoader.item
    if (!item) return
    if ("omarchyPath" in item) item.omarchyPath = root.omarchyPath
    if ("shell" in item) item.shell = root.shell
    if ("manifest" in item) item.manifest = root.manifest
    if ("pluginRegistry" in item) item.pluginRegistry = root.pluginRegistry
    if ("barWidgetRegistry" in item) item.barWidgetRegistry = root.barWidgetRegistry
  }

  function open(payloadJson) {
    if (barHostAvailable) {
      shell.bar.openMenu(payloadJson || "{}")
      return
    }
    var item = ensureFallback()
    if (item && typeof item.open === "function") item.open(payloadJson || "{}")
  }

  function close() {
    if (barHostAvailable) {
      shell.bar.closeMenu()
      unloadFallback()
      return
    }
    var item = fallbackLoader.item
    if (item && typeof item.close === "function") item.close()
  }

  onOmarchyPathChanged: configureFallback()
  onShellChanged: configureFallback()
  onManifestChanged: configureFallback()
  onPluginRegistryChanged: configureFallback()
  onBarWidgetRegistryChanged: configureFallback()
  onBarHostAvailableChanged: if (barHostAvailable) unloadFallback()

  Loader {
    id: fallbackLoader

    active: false
    sourceComponent: MenuWindow {
      omarchyPath: root.omarchyPath
      shell: root.shell
      manifest: root.manifest
      pluginRegistry: root.pluginRegistry
      barWidgetRegistry: root.barWidgetRegistry
    }
    onLoaded: root.configureFallback()
  }
}
