import QtQuick

Item {
  id: root

  signal revealRequested(string screenName, string reason)
  signal concealRequested(string reason)

  property bool enabled: false
  property int hotZoneWidth: 3
  property int revealDelayMs: 120
  property int hideDelayMs: 350
  property string phase: enabled ? "concealed" : "disabled"
  property string activeScreenName: ""
  property string candidateScreenName: ""
  property string queuedScreenName: ""
  property string queuedReason: "edge"
  property bool explicitHeld: false
  property bool flyoutHeld: false
  property bool contentHeld: false
  property string rearmBlockedScreenName: ""
  property int intentRevision: 0
  property var eligibleScreens: ({})
  property var suppressedScreens: ({})
  property var hotZoneHover: ({})
  property var sidebarHover: ({})
  property var connectorHover: ({})
  property var flyoutHover: ({})

  readonly property bool semanticHold: explicitHeld || flyoutHeld || contentHeld
  readonly property bool activePointerInside: activeScreenName !== "" && (
    mapValue(hotZoneHover, activeScreenName)
      || mapValue(sidebarHover, activeScreenName)
      || mapValue(connectorHover, activeScreenName)
      || mapValue(flyoutHover, activeScreenName))

  function copyMap(source) {
    var next = {}
    for (var key in source) next[key] = source[key]
    return next
  }

  function mapValue(source, key) {
    return key !== "" && source && source[key] === true
  }

  function setMapValue(propertyName, screenName, value) {
    var name = String(screenName || "")
    if (name === "") return
    var next = copyMap(root[propertyName] || ({}))
    if (value === true) next[name] = true
    else delete next[name]
    root[propertyName] = next
  }

  function screenEligible(screenName) {
    return mapValue(eligibleScreens, String(screenName || ""))
  }

  function screenSuppressed(screenName) {
    return mapValue(suppressedScreens, String(screenName || ""))
  }

  function setEligibleScreens(screenNames) {
    var next = {}
    var names = Array.isArray(screenNames) ? screenNames : []
    for (var i = 0; i < names.length; i++) {
      var name = String(names[i] || "")
      if (name !== "") next[name] = true
    }
    eligibleScreens = next
    if (candidateScreenName !== "" && !screenEligible(candidateScreenName)) cancelRevealPending()
    if (activeScreenName !== "" && !screenEligible(activeScreenName)) requestConceal("monitor-removed")
  }

  function setScreenSuppressed(screenName, suppressed) {
    var name = String(screenName || "")
    setMapValue("suppressedScreens", name, suppressed)
    if (suppressed === true) {
      if (candidateScreenName === name) cancelRevealPending()
      if (activeScreenName === name) requestConceal("fullscreen")
    }
  }

  function setHotZoneHovered(screenName, hovered) {
    var name = String(screenName || "")
    setMapValue("hotZoneHover", name, hovered)
    if (hovered !== true) {
      if (rearmBlockedScreenName === name) rearmBlockedScreenName = ""
      if (candidateScreenName === name) cancelRevealPending()
      scheduleEnvelopeEvaluation()
      return
    }
    if (!enabled || !screenEligible(name) || screenSuppressed(name)
        || rearmBlockedScreenName === name) return
    if (activeScreenName === name) {
      hideTimer.stop()
      if (phase === "hiding") {
        phase = "revealing"
        intentRevision += 1
        revealRequested(name, "edge-reversal")
      }
      return
    }
    if (activeScreenName !== "") {
      // A held session owns its output until the semantic interaction ends.
      // Merely crossing another output's edge must not dismiss a flyout,
      // keyboard edit, modal confirmation, or explicit menu open.
      if (semanticHold) return
      queuedScreenName = name
      queuedReason = "edge-handoff"
      requestConceal("output-handoff")
      return
    }
    candidateScreenName = name
    phase = "revealPending"
    intentRevision += 1
    revealTimer.restart()
  }

  function setSidebarHovered(screenName, hovered) {
    setMapValue("sidebarHover", String(screenName || ""), hovered)
    scheduleEnvelopeEvaluation()
  }

  function setConnectorHovered(screenName, hovered) {
    setMapValue("connectorHover", String(screenName || ""), hovered)
    scheduleEnvelopeEvaluation()
  }

  function setFlyoutHovered(screenName, hovered) {
    setMapValue("flyoutHover", String(screenName || ""), hovered)
    scheduleEnvelopeEvaluation()
  }

  function scheduleEnvelopeEvaluation() {
    envelopeEvaluation.restart()
  }

  function evaluateEnvelope() {
    if (!enabled || activeScreenName === "" || semanticHold || activePointerInside) {
      hideTimer.stop()
      if (enabled && activeScreenName !== "" && phase === "hidePending") phase = explicitHeld ? "held" : "visible"
      return
    }
    if (phase === "revealing" || phase === "visible" || phase === "held") {
      phase = "hidePending"
      intentRevision += 1
      hideTimer.restart()
    }
  }

  function cancelRevealPending() {
    revealTimer.stop()
    candidateScreenName = ""
    if (activeScreenName === "") phase = enabled ? "concealed" : "disabled"
  }

  function requestImmediateReveal(screenName, reason, holdOpen) {
    var name = String(screenName || "")
    if (!enabled || name === "" || !screenEligible(name) || screenSuppressed(name)) return false
    revealTimer.stop()
    hideTimer.stop()
    candidateScreenName = ""
    if (holdOpen === true) explicitHeld = true
    if (activeScreenName !== "" && activeScreenName !== name) {
      queuedScreenName = name
      queuedReason = String(reason || "explicit")
      requestConceal("output-handoff")
      return true
    }
    activeScreenName = name
    phase = explicitHeld ? "held" : "revealing"
    intentRevision += 1
    revealRequested(name, String(reason || "explicit"))
    return true
  }

  function explicitOpen(screenName) {
    return requestImmediateReveal(screenName, "explicit-open", true)
  }

  function explicitClose(reason) {
    var blocked = activeScreenName
    explicitHeld = false
    queuedScreenName = ""
    if (blocked !== "" && mapValue(hotZoneHover, blocked)) rearmBlockedScreenName = blocked
    requestConceal(String(reason || "explicit-close"))
  }

  function requestConceal(reason) {
    revealTimer.stop()
    hideTimer.stop()
    candidateScreenName = ""
    if (activeScreenName === "") {
      phase = enabled ? "concealed" : "disabled"
      return
    }
    phase = screenSuppressed(activeScreenName) ? "suppressed" : "hiding"
    intentRevision += 1
    concealRequested(String(reason || "pointer-leave"))
  }

  function notifyMenuProgress(progress) {
    var value = Number(progress)
    if (!isFinite(value)) return
    if (value >= 0.999 && activeScreenName !== "") {
      phase = explicitHeld ? "held" : "visible"
      evaluateEnvelope()
      return
    }
    if (value > 0.001 || activeScreenName === "") return
    activeScreenName = ""
    explicitHeld = false
    phase = enabled ? "concealed" : "disabled"
    if (queuedScreenName !== "") {
      var next = queuedScreenName
      var reason = queuedReason
      queuedScreenName = ""
      queuedReason = "edge"
      if (mapValue(hotZoneHover, next) || reason === "explicit-open")
        requestImmediateReveal(next, reason, reason === "explicit-open")
    }
  }

  onSemanticHoldChanged: scheduleEnvelopeEvaluation()

  onEnabledChanged: {
    revealTimer.stop()
    hideTimer.stop()
    envelopeEvaluation.stop()
    intentRevision += 1
    candidateScreenName = ""
    queuedScreenName = ""
    explicitHeld = false
    rearmBlockedScreenName = ""
    if (!enabled) {
      activeScreenName = ""
      phase = "disabled"
    } else if (activeScreenName === "") {
      phase = "concealed"
    }
  }

  Timer {
    id: revealTimer
    interval: Math.max(0, root.revealDelayMs)
    repeat: false
    onTriggered: {
      var name = root.candidateScreenName
      root.candidateScreenName = ""
      if (!root.enabled || !root.mapValue(root.hotZoneHover, name)
          || !root.screenEligible(name) || root.screenSuppressed(name)
          || root.rearmBlockedScreenName === name) {
        root.phase = root.activeScreenName === "" ? "concealed" : root.phase
        return
      }
      root.requestImmediateReveal(name, "edge-dwell", false)
    }
  }

  Timer {
    id: hideTimer
    interval: Math.max(0, root.hideDelayMs)
    repeat: false
    onTriggered: {
      if (!root.semanticHold && !root.activePointerInside) root.requestConceal("pointer-leave")
      else root.evaluateEnvelope()
    }
  }

  Timer {
    id: envelopeEvaluation
    interval: 0
    repeat: false
    onTriggered: root.evaluateEnvelope()
  }
}
