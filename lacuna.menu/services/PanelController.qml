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
  property int contentSwitchRevision: -1
  property real menuAnimationTarget: 0
  property real flyoutAnimationTarget: 0
  property string menuStateName: "closed"
  property string flyoutStateName: "closed"
  property string pendingFlyout: ""
  property string activeFlyout: ""
  property string incomingFlyout: ""
  property string outgoingFlyout: ""
  property string retainedFlyout: ""
  property string closingFlyout: ""
  property string visibleFlyout: ""
  property real menuProgress: 0
  property real flyoutProgress: 0
  property real contentSwitchProgress: 1
  property real outgoingFlyoutWeight: 0
  property real retainedFlyoutWeight: 0
  property real closingFlyoutWeight: 0
  property int animationDuration: motionTokens.animationNormal

  readonly property real menuToFlyoutThreshold: 0.65
  readonly property real flyoutContentThreshold: 0.55
  readonly property bool animationDisabled: motionTokens.animationDisabled
  readonly property bool menuOpen: menuState && menuState.open
  readonly property bool flyoutOpen: activeFlyout !== ""
  readonly property bool flyoutVisible: visibleFlyout !== ""
  readonly property bool menuRenderable: panelVisible
  readonly property bool flyoutRenderable: visibleFlyout !== "" || incomingFlyout !== ""
  readonly property bool menuInteractive: menuOpen && menuProgress > 0.98
  readonly property real contentProgress: Math.max(0, Math.min(1,
    (flyoutProgress - flyoutContentThreshold) / (1 - flyoutContentThreshold)))
  readonly property bool flyoutInteractive: flyoutOpen && flyoutRenderable
    && contentProgress > 0.98 && contentSwitchProgress > 0.98

  property MotionTokens motionTokens: defaultMotionTokens

  MotionTokens { id: defaultMotionTokens }

  function nextRevision() {
    transitionRevision += 1
    return transitionRevision
  }

  function animateMenu(to) {
    if (menuAnimationRevision >= 0 && menuAnimationTarget === to) return
    menuAnimationRevision = -1
    menuProgressAnim.stop()
    menuAnimationTarget = to
    if (animationDisabled || Math.abs(menuProgress - to) <= 0.001) {
      menuProgress = to
      menuAnimationRevision = nextRevision()
      completeMenuAnimation(menuAnimationRevision)
      return
    }
    menuAnimationRevision = nextRevision()
    menuProgressAnim.to = to
    menuProgressAnim.start()
  }

  function animateFlyout(to) {
    if (flyoutAnimationRevision >= 0 && flyoutAnimationTarget === to) return
    flyoutAnimationRevision = -1
    flyoutProgressAnim.stop()
    flyoutAnimationTarget = to
    if (animationDisabled || Math.abs(flyoutProgress - to) <= 0.001) {
      flyoutProgress = to
      flyoutAnimationRevision = nextRevision()
      completeFlyoutAnimation(flyoutAnimationRevision)
      return
    }
    flyoutAnimationRevision = nextRevision()
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
      consumePendingFlyout()
    }
    menuAnimationRevision = -1
  }

  function completeFlyoutAnimation(revision) {
    if (revision < 0 || revision !== flyoutAnimationRevision) return
    if (flyoutAnimationTarget <= 0 && flyoutProgress <= 0.001) {
      flyoutProgress = 0
      visibleFlyout = ""
      outgoingFlyout = ""
      retainedFlyout = ""
      closingFlyout = ""
      incomingFlyout = ""
      contentSwitchProgress = 1
      outgoingFlyoutWeight = 0
      retainedFlyoutWeight = 0
      closingFlyoutWeight = 0
      flyoutStateName = "closed"
    } else if (flyoutAnimationTarget >= 1 && flyoutProgress >= 0.999) {
      flyoutProgress = 1
      flyoutStateName = activeFlyout === "" ? "closed" : "flyoutOpen"
    }
    flyoutAnimationRevision = -1
  }

  function beginContentSwitch(next) {
    contentSwitchRevision = -1
    contentSwitchAnim.stop()
    if (incomingFlyout !== "") {
      // Preserve the actual A/B blend before starting the B/C transition.
      retainedFlyout = outgoingFlyout
      retainedFlyoutWeight = outgoingFlyoutWeight * (1 - contentSwitchProgress)
      outgoingFlyout = activeFlyout
      outgoingFlyoutWeight = contentSwitchProgress
    } else {
      retainedFlyout = ""
      retainedFlyoutWeight = 0
      closingFlyout = ""
      closingFlyoutWeight = 0
      outgoingFlyout = visibleFlyout
      outgoingFlyoutWeight = outgoingFlyout === "" ? 0 : 1
    }
    incomingFlyout = next
    activeFlyout = next
    contentSwitchProgress = 0
    flyoutStateName = "switchingFlyout"
    animateFlyout(1)
    if (animationDisabled) {
      contentSwitchRevision = nextRevision()
      completeContentSwitch(contentSwitchRevision)
      return
    }
    contentSwitchRevision = nextRevision()
    contentSwitchAnim.start()
  }

  function completeContentSwitch(revision) {
    if (revision < 0 || revision !== contentSwitchRevision) return
    contentSwitchProgress = 1
    visibleFlyout = activeFlyout
    incomingFlyout = ""
    outgoingFlyout = ""
    retainedFlyout = ""
    closingFlyout = ""
    flyoutStateName = activeFlyout === "" ? "closed" : "flyoutOpen"
    outgoingFlyoutWeight = 0
    retainedFlyoutWeight = 0
    closingFlyoutWeight = 0
    contentSwitchRevision = -1
  }

  function beginMenuOpening() {
    hostClosing = false
    panelVisible = true
    menuStateName = "openingMenu"
    animateMenu(1)
  }

  function beginMenuClosing() {
    pendingFlyout = ""
    menuStateName = "closingMenu"
    closeActiveFlyout()
    animateMenu(0)
  }

  function openMenu() {
    if (menuOpen) {
      beginMenuOpening()
      return
    }
    if (menuState && typeof menuState.show === "function") menuState.show()
    else {
      panelVisible = true
      menuStateName = "openingMenu"
      animateMenu(1)
    }
  }

  function closeMenu() {
    pendingFlyout = ""
    if (!menuOpen) {
      beginMenuClosing()
      return
    }
    hostClosing = true
    if (menuState && typeof menuState.close === "function") menuState.close()
    else beginMenuClosing()
    hostClosing = false
  }

  function toggleMenu() { if (menuOpen) closeMenu(); else openMenu() }
  function isFlyoutOpen(id) { return activeFlyout === String(id || "") }
  function isFlyoutVisible(id) { return visibleFlyout === String(id || "") || incomingFlyout === String(id || "") }

  function consumePendingFlyout() {
    if (pendingFlyout === "" || menuProgress < menuToFlyoutThreshold) return
    var next = pendingFlyout
    pendingFlyout = ""
    openFlyoutNow(next)
  }

  function openFlyout(id) {
    var next = String(id || "")
    if (next === "") return
    if (!menuOpen || menuProgress < menuToFlyoutThreshold) {
      pendingFlyout = next
      openMenu()
      return
    }
    openFlyoutNow(next)
  }

  function openFlyoutNow(next) {
    if (next === "") return
    if (activeFlyout === next && incomingFlyout === "") {
      animateFlyout(1)
      return
    }
    if (flyoutRenderable && (visibleFlyout !== "" || incomingFlyout !== "")) {
      // The host snapshots its current effective geometry while the controller
      // retains every currently visible content contribution.
      beginContentSwitch(next)
      return
    }
    contentSwitchRevision = -1
    contentSwitchAnim.stop()
    activeFlyout = next
    visibleFlyout = next
    incomingFlyout = ""
    outgoingFlyout = ""
    retainedFlyout = ""
    closingFlyout = ""
    contentSwitchProgress = 1
    outgoingFlyoutWeight = 0
    retainedFlyoutWeight = 0
    closingFlyoutWeight = 0
    flyoutStateName = "openingFlyout"
    animateFlyout(1)
  }

  function closeFlyout(id) { if (isFlyoutOpen(id)) closeActiveFlyout() }
  function toggleFlyout(id) { if (isFlyoutOpen(id)) closeActiveFlyout(); else openFlyout(id) }

  function closeActiveFlyout() {
    pendingFlyout = ""
    if (activeFlyout === "" && visibleFlyout === "") return
    contentSwitchRevision = -1
    contentSwitchAnim.stop()
    if (incomingFlyout !== "") {
      // Freeze the current composite so closing fades precisely what was on
      // screen instead of promoting the partially incoming content.
      retainedFlyoutWeight = retainedFlyoutWeight * (1 - contentSwitchProgress)
      outgoingFlyoutWeight = outgoingFlyoutWeight * (1 - contentSwitchProgress)
      closingFlyout = activeFlyout
      closingFlyoutWeight = contentSwitchProgress
    } else {
      if (visibleFlyout === "") visibleFlyout = activeFlyout
      retainedFlyout = ""
      retainedFlyoutWeight = 0
      closingFlyout = ""
      closingFlyoutWeight = 0
      outgoingFlyout = visibleFlyout
      outgoingFlyoutWeight = outgoingFlyout === "" ? 0 : 1
    }
    incomingFlyout = ""
    contentSwitchProgress = 1
    activeFlyout = ""
    flyoutStateName = "closingFlyout"
    animateFlyout(0)
  }

  onMenuProgressChanged: consumePendingFlyout()

  // This is deliberately only the content-switch blend. The attached shell
  // applies contentProgress once, after geometry has crossed its threshold.
  function contentSwitchOpacity(id) {
    var kind = String(id || "")
    var opacity = 0
    if (incomingFlyout !== "") {
      // A reversal such as A -> B -> A gives A both retained and incoming
      // roles. Sum every matching contribution instead of returning the first
      // one, otherwise the composite loses opacity during the reversal.
      if (kind === retainedFlyout) opacity += retainedFlyoutWeight * (1 - contentSwitchProgress)
      if (kind === outgoingFlyout) opacity += outgoingFlyoutWeight * (1 - contentSwitchProgress)
      if (kind === activeFlyout) opacity += contentSwitchProgress
      return Math.max(0, Math.min(1, opacity))
    }
    if (kind === retainedFlyout) opacity += retainedFlyoutWeight
    if (kind === outgoingFlyout) opacity += outgoingFlyoutWeight
    if (kind === closingFlyout) opacity += closingFlyoutWeight
    // visibleFlyout remains populated during close for render lifetime. Only
    // use its default full contribution when no frozen weighted composite is
    // active, otherwise it would double-count the closing content.
    if (opacity <= 0 && retainedFlyout === "" && outgoingFlyout === "" && closingFlyout === ""
        && kind === visibleFlyout) opacity = 1
    return Math.max(0, Math.min(1, opacity))
  }

  Connections {
    target: root.menuState
    function onOpenChanged() {
      if (!root.menuState) return
      if (root.menuState.open) root.beginMenuOpening()
      else {
        root.beginMenuClosing()
        if (!root.hostClosing) root.hostHideRequested()
      }
    }
  }

  NumberAnimation {
    id: menuProgressAnim
    target: root
    property: "menuProgress"
    duration: root.animationDuration
    easing.type: Easing.BezierSpline
    easing.bezierCurve: root.motionTokens.panelBezierCurve
    onStopped: root.completeMenuAnimation(root.menuAnimationRevision)
  }

  NumberAnimation {
    id: flyoutProgressAnim
    target: root
    property: "flyoutProgress"
    duration: root.animationDuration
    easing.type: Easing.BezierSpline
    easing.bezierCurve: root.motionTokens.panelBezierCurve
    onStopped: root.completeFlyoutAnimation(root.flyoutAnimationRevision)
  }

  NumberAnimation {
    id: contentSwitchAnim
    target: root
    property: "contentSwitchProgress"
    from: 0
    to: 1
    duration: root.motionTokens.quick
    easing.type: Easing.OutCubic
    onStopped: root.completeContentSwitch(root.contentSwitchRevision)
  }
}
