import QtQuick

Item {
  id: root

  signal hostHideRequested()

  property var menuState: null
  property bool hostClosing: false
  property bool panelVisible: false
  property int transitionRevision: 0
  property int menuAnimationRevision: -1
  property int flyoutAnimationRevision: -1
  property real menuAnimationTarget: 0
  property real flyoutAnimationTarget: 0
  property string menuStateName: "closed"
  property string flyoutStateName: "closed"
  property string activeFlyout: ""
  property string outgoingFlyout: ""
  property string visibleFlyout: ""
  property real menuProgress: 0
  property real flyoutProgress: 0
  property int animationDuration: motionTokens.animationNormal

  readonly property bool menuOpen: menuState && menuState.open
  readonly property bool flyoutOpen: activeFlyout !== ""
  readonly property bool flyoutVisible: visibleFlyout !== ""
  readonly property bool menuRenderable: panelVisible
  readonly property bool flyoutRenderable: visibleFlyout !== ""
  readonly property bool menuInteractive: menuOpen && menuProgress > 0.98
  readonly property real contentProgress: Math.max(0, Math.min(1, (flyoutProgress - 0.45) / 0.55))
  readonly property bool flyoutInteractive: flyoutOpen && flyoutVisible && contentProgress > 0.98

  property MotionTokens motionTokens: defaultMotionTokens

  MotionTokens {
    id: defaultMotionTokens
  }

  function nextRevision() {
    transitionRevision += 1
    return transitionRevision
  }

  function animateMenu(to) {
    if (menuAnimationRevision >= 0 && menuAnimationTarget === to) return
    if (Math.abs(menuProgress - to) <= 0.001) {
      menuProgress = to
      if (to >= 1) {
        panelVisible = true
        menuStateName = "menuOpen"
      } else {
        panelVisible = false
        menuStateName = "closed"
      }
      menuAnimationRevision = -1
      menuAnimationTarget = to
      return
    }

    menuAnimationRevision = -1
    menuProgressAnim.stop()
    menuAnimationRevision = nextRevision()
    menuAnimationTarget = to
    menuProgressAnim.to = to
    menuProgressAnim.start()
  }

  function animateFlyout(to) {
    flyoutAnimationRevision = -1
    flyoutProgressAnim.stop()
    flyoutAnimationRevision = nextRevision()
    flyoutAnimationTarget = to
    flyoutProgressAnim.to = to
    flyoutProgressAnim.start()
  }

  function completeMenuAnimation(revision) {
    if (revision < 0 || revision !== menuAnimationRevision) return

    if (menuAnimationTarget <= 0 && menuProgress <= 0.001) {
      menuProgress = 0
      panelVisible = false
      menuStateName = "closed"
    } else if (menuAnimationTarget >= 1 && menuProgress >= 0.999) {
      menuProgress = 1
      panelVisible = true
      menuStateName = "menuOpen"
    }

    menuAnimationRevision = -1
  }

  function completeFlyoutAnimation(revision) {
    if (revision < 0 || revision !== flyoutAnimationRevision) return

    if (flyoutAnimationTarget <= 0 && flyoutProgress <= 0.001) {
      flyoutProgress = 0
      visibleFlyout = ""
      outgoingFlyout = ""
      flyoutStateName = "closed"
    } else if (flyoutAnimationTarget >= 1 && flyoutProgress >= 0.999) {
      flyoutProgress = 1
      outgoingFlyout = ""
      flyoutStateName = activeFlyout === "" ? "closed" : "flyoutOpen"
    }

    flyoutAnimationRevision = -1
  }

  function setOutgoingFlyout(id) {
    outgoingFlyout = String(id || "")
    if (outgoingFlyout !== "") contentSwitchTimer.restart()
    else contentSwitchTimer.stop()
  }

  function beginMenuOpening() {
    hostClosing = false
    panelVisible = true
    if (menuProgress >= 0.999) {
      menuProgress = 1
      menuStateName = "menuOpen"
      menuAnimationRevision = -1
      menuAnimationTarget = 1
      return
    }

    menuStateName = "openingMenu"
    animateMenu(1)
  }

  function beginMenuClosing() {
    menuStateName = "closingMenu"
    closeActiveFlyout()
    animateMenu(0)
  }

  function openMenu() {
    if (menuOpen) {
      if (!panelVisible || menuProgress < 0.999) beginMenuOpening()
      else {
        panelVisible = true
        menuProgress = 1
        menuStateName = "menuOpen"
        menuAnimationRevision = -1
        menuAnimationTarget = 1
      }
      return
    }

    if (menuState && typeof menuState.show === "function") {
      menuState.show()
    } else {
      menuProgress = 1
      panelVisible = true
      menuStateName = "menuOpen"
    }
  }

  function closeMenu() {
    if (!menuOpen) {
      beginMenuClosing()
      return
    }

    hostClosing = true
    if (menuState && typeof menuState.close === "function") {
      menuState.close()
    } else {
      beginMenuClosing()
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
    setOutgoingFlyout(activeFlyout !== "" && activeFlyout !== next ? activeFlyout : "")
    activeFlyout = next
    visibleFlyout = next
    if (wasVisible && flyoutProgress > 0.98) {
      flyoutProgress = 1
      flyoutStateName = "flyoutOpen"
    } else {
      flyoutStateName = wasVisible ? "switchingFlyout" : "openingFlyout"
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
    setOutgoingFlyout(activeFlyout)
    activeFlyout = ""
    flyoutStateName = "closingFlyout"
    animateFlyout(0)
  }

  Connections {
    target: root.menuState

    function onOpenChanged() {
      if (!root.menuState) return
      if (root.menuState.open) {
        root.beginMenuOpening()
        return
      }

      root.beginMenuClosing()
      if (!root.hostClosing) root.hostHideRequested()
    }
  }

  NumberAnimation {
    id: menuProgressAnim

    target: root
    property: "menuProgress"
    duration: root.animationDuration
    easing.type: Easing.BezierSpline
    easing.bezierCurve: root.motionTokens.panelBezierCurve
    onStopped: {
      root.completeMenuAnimation(root.menuAnimationRevision)
    }
  }

  NumberAnimation {
    id: flyoutProgressAnim

    target: root
    property: "flyoutProgress"
    duration: root.animationDuration
    easing.type: Easing.BezierSpline
    easing.bezierCurve: root.motionTokens.panelBezierCurve
    onStopped: {
      root.completeFlyoutAnimation(root.flyoutAnimationRevision)
    }
  }

  Timer {
    id: contentSwitchTimer

    interval: root.motionTokens.animationFast
    repeat: false
    onTriggered: root.outgoingFlyout = ""
  }
}
