import QtQuick

Item {
  id: root

  signal hostHideRequested()

  property var menuState: null
  property bool hostClosing: false
  property bool panelVisible: false
  property string activeFlyout: ""
  property string visibleFlyout: ""
  property real menuProgress: 0
  property real flyoutProgress: 0
  property int animationDuration: 180

  readonly property bool menuOpen: menuState && menuState.open
  readonly property bool flyoutOpen: activeFlyout !== ""
  readonly property bool flyoutVisible: visibleFlyout !== ""
  readonly property bool menuInteractive: menuOpen && menuProgress > 0.98
  readonly property bool flyoutInteractive: flyoutOpen && flyoutVisible

  function animateMenu(to) {
    menuProgressAnim.stop()
    menuProgressAnim.to = to
    menuProgressAnim.start()
  }

  function animateFlyout(to) {
    flyoutProgressAnim.stop()
    flyoutProgressAnim.to = to
    flyoutProgressAnim.start()
  }

  function openMenu() {
    hostClosing = false
    panelVisible = true
    if (menuState && typeof menuState.show === "function") {
      menuState.show()
      if (menuOpen) animateMenu(1)
    } else {
      menuProgress = 1
      panelVisible = true
    }
  }

  function closeMenu() {
    hostClosing = true
    closeActiveFlyout()
    if (menuState && typeof menuState.close === "function") {
      menuState.close()
      if (!menuOpen) animateMenu(0)
    } else {
      animateMenu(0)
    }
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

    var wasVisible = visibleFlyout !== ""
    activeFlyout = next
    visibleFlyout = next
    if (wasVisible && flyoutProgress > 0.98) {
      flyoutProgress = 1
    } else {
      animateFlyout(1)
    }
  }

  function closeFlyout(id) {
    if (isFlyoutOpen(id)) closeActiveFlyout()
  }

  function toggleFlyout(id) {
    if (isFlyoutOpen(id)) closeActiveFlyout()
    else openFlyout(id)
  }

  function closeActiveFlyout() {
    if (activeFlyout === "" && visibleFlyout === "") return
    if (visibleFlyout === "") visibleFlyout = activeFlyout
    activeFlyout = ""
    animateFlyout(0)
  }

  Connections {
    target: root.menuState

    function onOpenChanged() {
      if (!root.menuState) return
      if (root.menuState.open) {
        root.panelVisible = true
        root.animateMenu(1)
        return
      }

      root.closeActiveFlyout()
      root.animateMenu(0)
      if (!root.hostClosing) root.hostHideRequested()
    }
  }

  NumberAnimation {
    id: menuProgressAnim

    target: root
    property: "menuProgress"
    duration: root.animationDuration
    easing.type: Easing.OutCubic
    onStopped: {
      if (!root.menuOpen && root.menuProgress <= 0.001) {
        root.menuProgress = 0
        root.panelVisible = false
      }
    }
  }

  NumberAnimation {
    id: flyoutProgressAnim

    target: root
    property: "flyoutProgress"
    duration: root.animationDuration
    easing.type: Easing.OutCubic
    onStopped: {
      if (root.activeFlyout === "" && root.flyoutProgress <= 0.001) {
        root.flyoutProgress = 0
        root.visibleFlyout = ""
      }
    }
  }
}
