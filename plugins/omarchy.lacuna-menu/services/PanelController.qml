import QtQuick

Item {
  id: root

  signal hostHideRequested()

  property var menuState: null
  property bool hostClosing: false
  property bool panelVisible: false
  property string activeFlyout: ""
  property string closingFlyout: ""
  property int flyoutCloseDelay: 220
  property int hideDelay: 190

  readonly property bool menuOpen: menuState && menuState.open
  readonly property bool flyoutOpen: activeFlyout !== ""
  readonly property string visibleFlyout: activeFlyout !== "" ? activeFlyout : closingFlyout
  readonly property bool flyoutVisible: visibleFlyout !== ""

  function openMenu() {
    hostClosing = false
    panelVisible = true
    if (menuState && typeof menuState.show === "function") menuState.show()
  }

  function closeMenu() {
    hostClosing = true
    closeActiveFlyout()
    if (menuState && typeof menuState.close === "function") menuState.close()
    else panelVisible = false
    hostClosing = false
  }

  function toggleMenu() {
    if (menuOpen) closeMenu()
    else openMenu()
  }

  function isFlyoutOpen(id) {
    return activeFlyout === String(id || "")
  }

  function isFlyoutVisible(id) {
    return visibleFlyout === String(id || "")
  }

  function openFlyout(id) {
    var next = String(id || "")
    if (next === "") return
    if (!menuOpen) openMenu()
    closeFlyoutTimer.stop()
    closingFlyout = ""
    activeFlyout = next
  }

  function closeFlyout(id) {
    if (isFlyoutOpen(id)) closeActiveFlyout()
  }

  function toggleFlyout(id) {
    if (isFlyoutOpen(id)) closeActiveFlyout()
    else openFlyout(id)
  }

  function closeActiveFlyout() {
    if (activeFlyout !== "") {
      closingFlyout = activeFlyout
      closeFlyoutTimer.restart()
    }
    activeFlyout = ""
  }

  Connections {
    target: root.menuState

    function onOpenChanged() {
      if (!root.menuState) return
      if (root.menuState.open) {
        hideTimer.stop()
        root.panelVisible = true
        return
      }

      root.closeActiveFlyout()
      hideTimer.restart()
      if (!root.hostClosing) root.hostHideRequested()
    }
  }

  Timer {
    id: closeFlyoutTimer
    interval: root.flyoutCloseDelay
    repeat: false
    onTriggered: root.closingFlyout = ""
  }

  Timer {
    id: hideTimer
    interval: root.hideDelay
    repeat: false
    onTriggered: if (!root.menuOpen) root.panelVisible = false
  }
}
