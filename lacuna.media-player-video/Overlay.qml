import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtMultimedia
import QtQuick

Item {
  id: root

  property string omarchyPath: ""
  property var shell: null
  property var manifest: null
  property var service: null

  readonly property string targetOutput: String(manifest && manifest.defaults && manifest.defaults.targetOutput !== undefined
    ? manifest.defaults.targetOutput : "ALL")
  readonly property bool allOutputs: targetOutput === "" || targetOutput === "ALL" || targetOutput === "*"
  readonly property string presentationMode: service && service.presentationMode !== undefined
    ? String(service.presentationMode || "auto")
    : "auto"
  readonly property string presentationState: service && service.presentationState !== undefined
    ? String(service.presentationState || "inline")
    : (service && service.backgroundVideoEnabled === true ? "background" : "inline")
  readonly property bool desiredBackgroundVideo: {
    // Demotion keeps the background alive until the inline surface reports
    // ready. Promotion likewise loads behind the cover while inline remains.
    if (presentationState === "promoting" || presentationState === "background"
        || presentationState === "demoting" || presentationState === "recovering") return true
    if (presentationState === "inline" && service && service.desiredBackgroundVideo !== undefined) {
      return service.desiredBackgroundVideo === true
    }
    if (presentationState === "inline") return false
    if (service && service.desiredBackgroundVideo !== undefined) return service.desiredBackgroundVideo === true
    return service && service.backgroundVideoEnabled === true
  }
  readonly property string videoQuality: service && service.videoQuality !== undefined
    ? String(service.videoQuality || "adaptive")
    : "adaptive"
  readonly property bool reducedMotion: service && (service.reduceMotion === true
    || (service.lacunaSettings && service.lacunaSettings.reduceMotion === true))
  readonly property string adaptiveVideoSource: service
    ? String(service.adaptiveBackgroundStreamUrl || "")
    : ""
  readonly property string progressiveVideoSource: service
    ? String(service.progressiveBackgroundStreamUrl || service.backgroundStreamUrl || "")
    : ""
  readonly property bool adaptivePreferred: videoQuality !== "stable"
    && videoQuality !== "progressive"
    && videoQuality !== "360p"
  readonly property string preferredVideoSource: adaptivePreferred && !usingProgressiveFallback && adaptiveVideoSource !== ""
    ? adaptiveVideoSource
    : progressiveVideoSource
  readonly property bool backgroundSurfaceDesired: desiredBackgroundVideo && service && service.playing === true
  readonly property bool backgroundVisible: backgroundSurfaceDesired && String(highResVideoSource) !== ""
  readonly property bool backgroundPlaying: backgroundSurfaceDesired && activeSource !== "" && service.paused !== true
  readonly property string highResVideoSource: preferredVideoSource
  readonly property int backgroundRequestRevision: service && service.backgroundRequestRevision !== undefined ? Number(service.backgroundRequestRevision) || 0 : 0
  readonly property int playbackSessionRevision: service && service.playbackSessionRevision !== undefined
    ? Number(service.playbackSessionRevision) || 0
    : backgroundRequestRevision
  readonly property bool backgroundResolveFailed: service && service.backgroundResolveFailed === true
  readonly property string videoSource: backgroundVisible ? highResVideoSource : ""
  readonly property real startPosition: service && service.playbackPosition !== undefined ? Math.max(0, Number(service.playbackPosition) || 0) : 0
  readonly property bool wallpaperDesired: backgroundVisible && videoSource !== ""
  readonly property bool waitingForHighRes: service
    && desiredBackgroundVideo
    && service.playing === true
    && service.paused !== true
    && highResVideoSource === ""
  readonly property int normalFadeCoverRiseDuration: 300
  readonly property int normalSourceHoldDuration: 150
  readonly property int normalFadeInDuration: 750
  readonly property int normalExitFadeToBlackDuration: 350
  readonly property int normalExitFadeFromBlackDuration: 600
  readonly property int reducedMotionDuration: 75
  readonly property int fadeCoverRiseDuration: transitionDuration(normalFadeCoverRiseDuration)
  readonly property int sourceHoldDuration: transitionDuration(normalSourceHoldDuration)
  readonly property int fadeInDuration: transitionDuration(normalFadeInDuration)
  readonly property int fadeOutDuration: transitionDuration(normalFadeInDuration)
  readonly property int exitFadeToBlackDuration: transitionDuration(normalExitFadeToBlackDuration)
  readonly property int exitFadeFromBlackDuration: transitionDuration(normalExitFadeFromBlackDuration)
  readonly property int handoffTimeoutDuration: 5000
  readonly property int adaptiveReadinessTimeoutDuration: 4000
  readonly property int hardSeekCooldownDuration: 1500
  readonly property int transitionSettleDelay: reducedMotion ? 5 : 24
  property string activeSource: ""
  property string activeCandidateKind: "none"
  property int activeStartPosition: 0
  property int mediaRestartAttempts: 0
  property int resolveRetryAttempts: 0
  property int wallpaperRecoveryAttempts: 0
  property bool usingProgressiveFallback: false
  property string fallbackReason: ""
  property int hardSeekFailureCount: 0
  property double lastHardSeekAt: 0
  property bool driftValidationPending: false
  property bool driftCorrectionBlocked: false
  property string lastReportedReadyKey: ""
  property string lastReportedFailureKey: ""
  property string activeRevisionKey: ""
  property int lastHandledResolveFailureRevision: -1
  property bool fadeCoverVisible: false
  property real fadeCoverOpacity: 0
  property double fadeCoverStartedAt: 0
  property double activeSourceAssignedAt: 0
  property int fadeRevealDelay: 0
  property bool fadeCoverRising: false
  property int fadeCoverDuration: fadeInDuration
  property bool exitTransitionActive: false
  property bool clearingWallpaperAfterExit: false
  property bool failureExitActive: false
  property string pendingGiveUpReason: ""
  property int wallpaperFadeGateDelay: 0
  property bool waitingForPlayerReady: false
  property bool wallpaperPositionRefreshPending: false
  property string wallpaperPositionRefreshKey: ""
  readonly property int mediaReadyMinimumHoldMs: sourceHoldDuration
  readonly property int failureWatchdogDuration: handoffTimeoutDuration
  readonly property bool wallpaperLayerVisible: wallpaperDesired || activeSource !== "" || exitTransitionActive || fadeCoverVisible

  function transitionDuration(normalDuration) {
    return reducedMotion ? reducedMotionDuration : normalDuration
  }

  function outputMatches(screen) {
    if (allOutputs) return true
    var name = screen && screen.name !== undefined ? String(screen.name) : ""
    return name === targetOutput
  }

  function resolveFrameRect(screen) {
    if (root.shell && root.shell.bar && typeof root.shell.bar.lacunaFrameContentRect === "function") {
      var rect = root.shell.bar.lacunaFrameContentRect(screen)
      if (rect && rect.width > 0 && rect.height > 0) return rect
    }
    return {
      x: 0,
      y: 0,
      width: screen && screen.width !== undefined ? Math.max(1, Number(screen.width) || 1) : 1,
      height: screen && screen.height !== undefined ? Math.max(1, Number(screen.height) || 1) : 1,
      radius: 0,
      bleed: 0,
      framed: false
    }
  }

  function resolveService() {
    if (root.service) return
    if (root.shell && typeof root.shell.ensureService === "function") {
      var ensured = root.shell.ensureService("lacuna.media-player")
      if (ensured) {
        root.service = ensured
        return
      }
    }
    if (root.shell && typeof root.shell.serviceFor === "function") {
      var existing = root.shell.serviceFor("lacuna.media-player")
      if (existing) root.service = existing
    }
  }

  function open(payloadJson) {
    resolveService()
  }

  Component.onCompleted: {
    resolveService()
    syncWallpaper()
  }
  onShellChanged: resolveService()
  onWaitingForHighResChanged: syncWallpaper()
  onBackgroundRequestRevisionChanged: {
    resetCandidateState()
    lastHandledResolveFailureRevision = -1
    if (backgroundResolveFailed) handleResolveFailure()
    syncWallpaper()
  }
  onPlaybackSessionRevisionChanged: {
    mediaRestartAttempts = 0
    resetCandidateState()
    syncWallpaper()
  }
  onBackgroundResolveFailedChanged: {
    if (backgroundResolveFailed) handleResolveFailure()
    else lastHandledResolveFailureRevision = -1
  }
  onPresentationModeChanged: syncWallpaper()
  onPresentationStateChanged: syncWallpaper()
  onDesiredBackgroundVideoChanged: syncWallpaper()
  onAdaptiveVideoSourceChanged: syncWallpaper()
  onProgressiveVideoSourceChanged: syncWallpaper()
  onVideoQualityChanged: {
    usingProgressiveFallback = false
    syncWallpaper()
  }
  onReducedMotionChanged: syncWallpaper()
  onWallpaperDesiredChanged: syncWallpaper()
  onVideoSourceChanged: syncWallpaper()
  onBackgroundPlayingChanged: syncWallpaper()
  onStartPositionChanged: syncVideoPosition(false)

  function resetCandidateState() {
    usingProgressiveFallback = false
    fallbackReason = ""
    hardSeekFailureCount = 0
    lastHardSeekAt = 0
    driftValidationPending = false
    driftCorrectionBlocked = false
    lastReportedReadyKey = ""
    lastReportedFailureKey = ""
    adaptiveReadinessTimer.stop()
    driftValidationTimer.stop()
    readyConvergenceTimer.stop()
  }

  function activePlayersConverged(toleranceMs) {
    var found = false
    var target = Math.max(0, startPosition * 1000)
    for (var i = 0; i < videoPlayers.length; i++) {
      var player = videoPlayers[i]
      if (!player || String(player.source) !== activeSource) continue
      found = true
      if (Math.abs(target - player.position) >= toleranceMs) return false
    }
    return found
  }

  function reportReady() {
    var key = playbackSessionRevision + "#" + activeSource
    if (lastReportedReadyKey === key) return
    lastReportedReadyKey = key
    var surfacePosition = startPosition
    for (var i = 0; i < videoPlayers.length; i++) {
      var player = videoPlayers[i]
      if (!player || String(player.source) !== activeSource) continue
      surfacePosition = Math.max(0, Number(player.position) / 1000)
      break
    }
    if (service && typeof service.reportVideoReady === "function") {
      service.reportVideoReady("background", playbackSessionRevision, surfacePosition)
    }
  }

  function reportFailure(reason) {
    var normalizedReason = String(reason || "unknown")
    var key = playbackSessionRevision + "#" + activeSource + "#" + normalizedReason
    if (lastReportedFailureKey === key) return
    lastReportedFailureKey = key
    if (service && typeof service.reportVideoFailure === "function") {
      service.reportVideoFailure("background", playbackSessionRevision, normalizedReason)
    }
  }

  function holdFadeCover(duration) {
    exitTransitionActive = false
    clearingWallpaperAfterExit = false
    failureExitActive = false
    pendingGiveUpReason = ""
    exitClearTimer.stop()
    failureClearTimer.stop()
    fadeRevealTimer.stop()
    fadeHideTimer.stop()
    fadeCoverVisible = true
    fadeCoverStartedAt = Date.now()
    fadeCoverRising = true
    fadeCoverDuration = Math.max(1, Number(duration) || fadeCoverRiseDuration)
    fadeCoverOpacity = 1
    failureWatchdog.restart()
  }

  function fadeCoverRiseRemaining() {
    if (!fadeCoverRising || fadeCoverStartedAt <= 0) return 0
    return Math.max(0, fadeCoverDuration - (Date.now() - fadeCoverStartedAt))
  }

  function releaseFadeCoverSoon() {
    var elapsed = activeSourceAssignedAt > 0 ? Date.now() - activeSourceAssignedAt : mediaReadyMinimumHoldMs
    fadeRevealDelay = Math.max(0, mediaReadyMinimumHoldMs - elapsed)
    fadeRevealTimer.restart()
  }

  function releaseFadeCoverNow() {
    fadeRevealTimer.stop()
    failureWatchdog.stop()
    waitingForPlayerReady = false
    fadeCoverRising = false
    fadeCoverDuration = clearingWallpaperAfterExit ? exitFadeFromBlackDuration : fadeOutDuration
    fadeCoverOpacity = 0
    fadeHideTimer.restart()
  }

  function anyPlayerReadyFor(source) {
    for (var i = 0; i < videoPlayers.length; i++) {
      var player = videoPlayers[i]
      if (!player || String(player.source) !== source) continue
      if (player.playbackState === MediaPlayer.PlayingState || player.mediaStatus === MediaPlayer.BufferedMedia) return true
    }
    return false
  }

  function notePlayerReady() {
    if (!waitingForPlayerReady || activeSource === "" || exitTransitionActive || !wallpaperDesired) return
    if (!activePlayersConverged(400)) {
      syncVideoPosition(false)
      readyConvergenceTimer.restart()
      return
    }
    readyConvergenceTimer.stop()
    adaptiveReadinessTimer.stop()
    resolveRetryAttempts = 0
    wallpaperRecoveryAttempts = 0
    mediaRestartAttempts = 0
    hardSeekFailureCount = 0
    driftCorrectionBlocked = false
    reportReady()
    releaseFadeCoverSoon()
  }

  function notePlayerError(message) {
    if (activeSource === "" || exitTransitionActive || !wallpaperDesired) return
    if (activeCandidateKind === "adaptive" && usingProgressiveFallback) return
    console.warn("lacuna.media-player-video: player error:", message, "restartAttempts:", mediaRestartAttempts)
    if (activeCandidateKind === "adaptive" && switchToProgressive("adaptive-error")) return
    if (mediaRestartAttempts < 2 && service && typeof service.refreshBackgroundStream === "function") {
      mediaRestartAttempts += 1
      waitingForPlayerReady = true
      holdFadeCover(fadeCoverRiseDuration)
      service.refreshBackgroundStream()
      failureWatchdog.restart()
      return
    }
    reportFailure(message || "player-error")
    giveUpWallpaper(message || "player-error")
  }

  function switchToProgressive(reason) {
    if (progressiveVideoSource === "" || activeCandidateKind === "progressive" || usingProgressiveFallback) return false
    fallbackReason = String(reason || "adaptive-fallback")
    usingProgressiveFallback = true
    adaptiveReadinessTimer.stop()
    waitingForPlayerReady = true
    hardSeekFailureCount = 0
    lastHardSeekAt = 0
    driftValidationPending = false
    driftCorrectionBlocked = false
    reportFailure(fallbackReason)
    holdFadeCover(fadeCoverRiseDuration)
    wallpaperFadeGateDelay = fadeCoverDuration
    wallpaperFadeGateTimer.restart()
    return true
  }

  function handleResolveFailure() {
    if (!backgroundResolveFailed) return
    if (lastHandledResolveFailureRevision === backgroundRequestRevision) return
    lastHandledResolveFailureRevision = backgroundRequestRevision
    var wantsVideo = desiredBackgroundVideo && service && service.playing === true && service.paused !== true
    if (wantsVideo && resolveRetryAttempts < 2 && service && typeof service.refreshBackgroundStream === "function") {
      resolveRetryAttempts += 1
      giveUpWallpaper("resolve-failed-retry-" + resolveRetryAttempts)
      resolveRetryTimer.restart()
      return
    }
    reportFailure("resolve-failed")
    giveUpWallpaper("resolve-failed")
  }

  function giveUpWallpaper(reason) {
    console.warn("lacuna.media-player-video: wallpaper gave up:", reason)
    wallpaperFadeGateTimer.stop()
    fadeRevealTimer.stop()
    adaptiveReadinessTimer.stop()
    driftValidationTimer.stop()
    failureWatchdog.stop()
    waitingForPlayerReady = false
    readyConvergenceTimer.stop()
    pendingGiveUpReason = String(reason || "unknown")
    if (activeSource !== "" && fadeCoverOpacity < 0.999) {
      failureExitActive = true
      fadeCoverVisible = true
      fadeCoverRising = true
      fadeCoverStartedAt = Date.now()
      fadeCoverDuration = exitFadeToBlackDuration
      fadeCoverOpacity = 1
      failureClearTimer.restart()
      return
    }
    finishGiveUpWallpaper()
  }

  function finishGiveUpWallpaper() {
    failureExitActive = false
    clearingWallpaperAfterExit = true
    activeSource = ""
    activeRevisionKey = ""
    activeCandidateKind = "none"
    activeStartPosition = 0
    mediaRestartAttempts = 0
    wallpaperPositionRefreshPending = false
    wallpaperPositionRefreshKey = ""
    driftValidationPending = false
    releaseFadeCoverNow()
    // Giving up while the service still wants video used to strand the
    // static background until the next track; retry a bounded number of
    // times instead.
    if (wallpaperDesired && wallpaperRecoveryAttempts < 2) {
      wallpaperRecoveryAttempts += 1
      wallpaperRecoveryTimer.restart()
    }
    pendingGiveUpReason = ""
  }

  function syncWallpaper() {
    if (failureExitActive) return
    if (!backgroundSurfaceDesired) {
      if (activeSource !== "" && !exitTransitionActive && !clearingWallpaperAfterExit) {
        beginWallpaperExit()
        return
      }
      if (!exitTransitionActive && !clearingWallpaperAfterExit) clearWallpaperNow()
      return
    }

    // Resolution is not a teardown signal. Keep the previous frame running
    // until a replacement candidate exists, then swap it under black.
    if (videoSource === "") return

    if (exitTransitionActive || clearingWallpaperAfterExit) {
      exitTransitionActive = false
      clearingWallpaperAfterExit = false
      exitClearTimer.stop()
      fadeHideTimer.stop()
      if (fadeCoverOpacity < 0.999) {
        holdFadeCover(fadeCoverRiseDuration)
        wallpaperFadeGateDelay = fadeCoverDuration
        wallpaperFadeGateTimer.restart()
        return
      }
    }

    var sourceRevisionKey = videoSource + "#" + backgroundRequestRevision + "#" + playbackSessionRevision
    if ((activeSource !== videoSource || activeRevisionKey !== sourceRevisionKey)
        && !fadeCoverRising && fadeCoverOpacity <= 0.001) {
      // Every appearance dips quickly to black and then reveals when the
      // player is actually ready — enabling the wallpaper feels the same as
      // a track change.
      holdFadeCover(fadeCoverRiseDuration)
      wallpaperFadeGateDelay = fadeCoverDuration
      wallpaperFadeGateTimer.restart()
      return
    }

    var remainingFadeCoverRise = fadeCoverRiseRemaining()
    if (remainingFadeCoverRise > 0) {
      wallpaperFadeGateDelay = Math.max(1, Math.ceil(remainingFadeCoverRise))
      wallpaperFadeGateTimer.restart()
      return
    }

    var refreshKey = sourceRevisionKey
    if (wallpaperPositionRefreshKey !== refreshKey && !wallpaperPositionRefreshPending && service && typeof service.updatePlaybackPosition === "function") {
      wallpaperPositionRefreshPending = true
      service.updatePlaybackPosition()
      wallpaperPositionRefreshTimer.restart()
      return
    }

    activeSource = videoSource
    activeRevisionKey = refreshKey
    activeCandidateKind = adaptiveVideoSource !== "" && activeSource === adaptiveVideoSource && !usingProgressiveFallback
      ? "adaptive"
      : "progressive"
    activeSourceAssignedAt = Date.now()
    activeStartPosition = Math.max(0, Math.floor(startPosition))
    waitingForPlayerReady = true
    failureWatchdog.restart()
    if (activeCandidateKind === "adaptive") adaptiveReadinessTimer.restart()
    else adaptiveReadinessTimer.stop()
    syncVideoPosition(true)
    // A track repeat re-resolves to the same cached stream URL, so the
    // player keeps playing and never emits a fresh ready transition —
    // release the cover ourselves or the watchdog tears the wallpaper down.
    if (anyPlayerReadyFor(activeSource)) notePlayerReady()
  }

  function beginWallpaperExit() {
    wallpaperFadeGateTimer.stop()
    fadeRevealTimer.stop()
    fadeHideTimer.stop()
    failureWatchdog.stop()
    adaptiveReadinessTimer.stop()
    readyConvergenceTimer.stop()
    driftValidationTimer.stop()
    wallpaperPositionRefreshTimer.stop()
    waitingForPlayerReady = false
    driftValidationPending = false
    driftCorrectionBlocked = false
    exitTransitionActive = true
    clearingWallpaperAfterExit = false
    failureExitActive = false
    failureClearTimer.stop()
    fadeCoverVisible = true
    fadeCoverRising = true
    fadeCoverStartedAt = Date.now()
    fadeCoverDuration = exitFadeToBlackDuration
    fadeCoverOpacity = 1
    exitClearTimer.restart()
  }

  function clearWallpaperNow() {
    activeSource = ""
    activeRevisionKey = ""
    activeCandidateKind = "none"
    activeStartPosition = 0
    activeSourceAssignedAt = 0
    mediaRestartAttempts = 0
    waitingForPlayerReady = false
    wallpaperPositionRefreshPending = false
    wallpaperPositionRefreshKey = ""
    wallpaperFadeGateTimer.stop()
    adaptiveReadinessTimer.stop()
    driftValidationTimer.stop()
    readyConvergenceTimer.stop()
    driftValidationPending = false
    if (!waitingForHighRes) releaseFadeCoverNow()
  }

  function syncVideoPosition(force) {
    if (exitTransitionActive || !wallpaperDesired) return
    if (driftCorrectionBlocked && !force) return
    var now = Date.now()
    var hardSeekAllowed = force || now - lastHardSeekAt >= hardSeekCooldownDuration
    var hardSeekIssued = false
    for (var i = 0; i < videoPlayers.length; i++) {
      var player = videoPlayers[i]
      if (!player || player.source === "") continue
      var target = Math.max(0, Math.round(startPosition * 1000))
      var drift = target - player.position
      var absoluteDrift = Math.abs(drift)

      if (force) {
        player.playbackRate = 1.0
        player.setPosition(target)
        continue
      }
      if (absoluteDrift < 400) {
        player.playbackRate = 1.0
        continue
      }
      if (absoluteDrift <= 1500) {
        player.playbackRate = drift > 0 ? 1.03 : 0.97
        continue
      }

      player.playbackRate = 1.0
      if (!hardSeekAllowed) continue
      player.setPosition(target)
      hardSeekIssued = true
    }
    if (hardSeekIssued && !force) {
      lastHardSeekAt = now
      driftValidationPending = true
      driftValidationTimer.restart()
    }
  }

  function validateHardSeek() {
    if (!driftValidationPending || exitTransitionActive || !wallpaperDesired) return
    driftValidationPending = false
    var worstDrift = 0
    for (var i = 0; i < videoPlayers.length; i++) {
      var player = videoPlayers[i]
      if (!player || player.source === "") continue
      worstDrift = Math.max(worstDrift, Math.abs(Math.max(0, startPosition * 1000) - player.position))
    }
    if (worstDrift <= 1500) {
      hardSeekFailureCount = 0
      return
    }
    hardSeekFailureCount += 1
    if (hardSeekFailureCount < 2) return
    if (activeCandidateKind === "adaptive" && switchToProgressive("adaptive-seek-correction")) return
    driftCorrectionBlocked = true
    reportFailure("seek-correction-failed")
    giveUpWallpaper("seek-correction-failed")
  }

  Component.onDestruction: {
    activeSource = ""
  }

  Timer {
    interval: 500
    repeat: true
    running: root.service === null
    onTriggered: root.resolveService()
  }

  Timer {
    id: fadeRevealTimer
    interval: root.fadeRevealDelay
    repeat: false
    onTriggered: root.releaseFadeCoverNow()
  }

  Timer {
    id: fadeHideTimer
    interval: root.fadeCoverDuration + root.transitionSettleDelay
    repeat: false
    onTriggered: {
      if (root.fadeCoverOpacity <= 0.001) {
        root.fadeCoverVisible = false
        root.clearingWallpaperAfterExit = false
      }
    }
  }

  Timer {
    id: exitClearTimer
    interval: root.exitFadeToBlackDuration + root.transitionSettleDelay
    repeat: false
    onTriggered: {
      if (!root.exitTransitionActive || root.wallpaperDesired) return
      root.exitTransitionActive = false
      root.clearingWallpaperAfterExit = true
      root.clearWallpaperNow()
    }
  }

  Timer {
    id: failureClearTimer
    interval: root.exitFadeToBlackDuration + root.transitionSettleDelay
    repeat: false
    onTriggered: {
      if (!root.failureExitActive) return
      root.finishGiveUpWallpaper()
    }
  }

  Timer {
    id: wallpaperFadeGateTimer
    interval: root.wallpaperFadeGateDelay
    repeat: false
    onTriggered: root.syncWallpaper()
  }

  Timer {
    id: failureWatchdog
    interval: root.failureWatchdogDuration
    repeat: false
    onTriggered: {
      if (!root.wallpaperDesired || root.exitTransitionActive) return
      // yt-dlp resolves can outlast the watchdog window (up to two 18s
      // attempts); while one is in flight, keep waiting instead of dropping
      // the wallpaper for a resolve that is about to succeed.
      if (root.service && root.service.resolvingBackground === true) {
        restart()
        return
      }
      if (root.waitingForHighRes || root.waitingForPlayerReady || root.backgroundResolveFailed) {
        root.reportFailure("handoff-timeout")
        root.giveUpWallpaper("handoff-timeout")
      }
    }
  }

  Timer {
    id: adaptiveReadinessTimer
    interval: root.adaptiveReadinessTimeoutDuration
    repeat: false
    onTriggered: {
      if (!root.wallpaperDesired || root.exitTransitionActive) return
      if (!root.waitingForPlayerReady || root.activeCandidateKind !== "adaptive") return
      if (!root.switchToProgressive("adaptive-readiness-timeout")) {
        root.reportFailure("adaptive-readiness-timeout")
        root.giveUpWallpaper("adaptive-readiness-timeout")
      }
    }
  }

  Timer {
    id: readyConvergenceTimer
    interval: 100
    repeat: false
    onTriggered: {
      if (root.waitingForPlayerReady && root.anyPlayerReadyFor(root.activeSource)) root.notePlayerReady()
    }
  }

  Timer {
    id: driftValidationTimer
    interval: 500
    repeat: false
    onTriggered: root.validateHardSeek()
  }

  Timer {
    id: wallpaperRecoveryTimer
    interval: 6000
    repeat: false
    onTriggered: {
      if (!root.wallpaperDesired || root.activeSource !== "") return
      root.syncWallpaper()
    }
  }

  Timer {
    id: resolveRetryTimer
    interval: 8000
    repeat: false
    onTriggered: {
      if (!root.backgroundResolveFailed) return
      if (!(root.desiredBackgroundVideo && root.service && root.service.playing === true && root.service.paused !== true)) return
      root.service.refreshBackgroundStream()
    }
  }

  Timer {
    id: wallpaperPositionRefreshTimer
    interval: 300
    repeat: false
    onTriggered: {
      root.wallpaperPositionRefreshKey = root.videoSource + "#" + root.backgroundRequestRevision + "#" + root.playbackSessionRevision
      root.wallpaperPositionRefreshPending = false
      root.syncWallpaper()
    }
  }

  property var videoPlayers: []

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: videoWindow

      required property var modelData
      readonly property bool targetMatched: root.outputMatches(modelData)
      readonly property var frameRect: root.resolveFrameRect(modelData)
      readonly property bool renderable: targetMatched && root.wallpaperLayerVisible

      screen: modelData
      // A background-layer surface cannot be restacked after mapping. Keep
      // it mapped from shell startup and gate only the in-window paint.
      visible: true
      color: "transparent"
      implicitWidth: 0
      implicitHeight: 0
      WlrLayershell.namespace: "lacuna-media-player-video"
      WlrLayershell.layer: WlrLayer.Background
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      exclusionMode: ExclusionMode.Ignore
      mask: Region {}

      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }

      Rectangle {
        id: videoFrame

        x: Math.round(videoWindow.frameRect.x)
        y: Math.round(videoWindow.frameRect.y)
        width: Math.round(videoWindow.frameRect.width)
        height: Math.round(videoWindow.frameRect.height)
        radius: Math.max(0, Number(videoWindow.frameRect.radius || 0))
        color: "transparent"
        clip: true
        visible: videoWindow.renderable

        MediaPlayer {
          id: backgroundPlayer
          source: videoWindow.renderable ? root.activeSource : ""
          videoOutput: backgroundOutput
          audioOutput: AudioOutput {
            muted: true
            volume: 0
          }
          loops: MediaPlayer.Infinite
          onSourceChanged: {
            root.syncVideoPosition(true)
            if (root.backgroundPlaying) play()
          }
          onPlaybackStateChanged: {
            if (playbackState === MediaPlayer.PlayingState) {
              // A handoff can resume the same source without onSourceChanged.
              // Force a fresh lock to the live mpv clock in that case.
              root.syncVideoPosition(true)
              root.notePlayerReady()
            }
            if (playbackState !== MediaPlayer.PlayingState) playbackRate = 1.0
          }
          onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.LoadedMedia || mediaStatus === MediaPlayer.BufferedMedia) {
              root.syncVideoPosition(true)
              root.notePlayerReady()
            }
            if (mediaStatus === MediaPlayer.InvalidMedia) root.notePlayerError("invalid-media")
          }
          onErrorOccurred: function(error, errorString) {
            if (error !== MediaPlayer.NoError) root.notePlayerError(errorString)
          }
          Component.onCompleted: root.videoPlayers.push(backgroundPlayer)
          Component.onDestruction: {
            var index = root.videoPlayers.indexOf(backgroundPlayer)
            if (index >= 0) root.videoPlayers.splice(index, 1)
          }
        }

        VideoOutput {
          id: backgroundOutput
          anchors.fill: parent
          visible: videoWindow.renderable
          fillMode: VideoOutput.PreserveAspectCrop
        }

        Rectangle {
          id: fadeCover

          // The black cover lives inside the video window, above the
          // VideoOutput: sibling z-order is deterministic, whereas stacking
          // two separate layer-shell surfaces is map-order dependent and
          // could leave the video on top of its own cover, turning every
          // fade into an abrupt pop-in.
          anchors.fill: parent
          z: 10
          color: "#000000"
          visible: root.fadeCoverVisible
          opacity: root.fadeCoverOpacity

          Behavior on opacity {
            NumberAnimation {
              duration: root.fadeCoverDuration
              easing.type: Easing.InOutQuad
            }
          }
        }

        Connections {
          target: root
          function onActiveSourceChanged() {
            if (root.activeSource === "") backgroundPlayer.stop()
            else if (root.backgroundPlaying && videoWindow.renderable) backgroundPlayer.play()
          }
          function onBackgroundPlayingChanged() {
            if (root.backgroundPlaying && videoWindow.renderable) {
              root.syncVideoPosition(true)
              backgroundPlayer.play()
            } else {
              backgroundPlayer.pause()
            }
          }
          function onWallpaperDesiredChanged() {
            if (root.wallpaperDesired && root.backgroundPlaying && videoWindow.renderable) {
              root.syncVideoPosition(true)
              backgroundPlayer.play()
            }
          }
        }
      }
    }
  }

  Connections {
    target: root.service

    function onBackgroundVideoEnabledChanged() { root.syncWallpaper() }
    function onPausedChanged() { root.syncWallpaper() }
    function onPlayingChanged() { root.syncWallpaper() }
    function onBackgroundStreamUrlChanged() { root.syncWallpaper() }
    function onPlaybackPositionChanged() { root.syncVideoPosition(false) }
    function onCurrentTrackUrlChanged() {
      root.resolveRetryAttempts = 0
      root.wallpaperRecoveryAttempts = 0
      root.resetCandidateState()
    }
  }

  IpcHandler {
    id: mediaPlayerVideoIpc

    target: "lacuna-media-player-video"

    function status(): string {
      return JSON.stringify({
        loaded: true,
        hasService: root.service !== null,
        backgroundVisible: root.backgroundVisible,
        backgroundPlaying: root.backgroundPlaying,
        wallpaperDesired: root.wallpaperDesired,
        wallpaperRunning: root.activeSource !== "",
        backgroundVideoEnabled: root.service && root.service.backgroundVideoEnabled === true,
        presentationMode: root.presentationMode,
        presentationState: root.presentationState,
        desiredBackgroundVideo: root.desiredBackgroundVideo,
        videoQuality: root.videoQuality,
        playing: root.service && root.service.playing === true,
        paused: root.service && root.service.paused === true,
        previewReady: root.service && String(root.service.previewStreamUrl || "") !== "",
        currentTrackUrl: root.service ? String(root.service.currentTrackUrl || "") : "",
        backgroundReady: root.service && String(root.service.backgroundStreamUrl || "") !== "",
        backgroundResolving: root.service && root.service.resolvingBackground === true,
        backgroundResolveFailed: root.backgroundResolveFailed,
        backgroundRequestRevision: root.backgroundRequestRevision,
        playbackSessionRevision: root.playbackSessionRevision,
        waitingForHighRes: root.waitingForHighRes,
        waitingForPlayerReady: root.waitingForPlayerReady,
        adaptiveReady: root.adaptiveVideoSource !== "",
        progressiveReady: root.progressiveVideoSource !== "",
        activeCandidateKind: root.activeCandidateKind,
        usingProgressiveFallback: root.usingProgressiveFallback,
        fallbackReason: root.fallbackReason,
        hardSeekFailureCount: root.hardSeekFailureCount,
        driftCorrectionBlocked: root.driftCorrectionBlocked,
        fadeCoverVisible: root.fadeCoverVisible,
        fadeCoverOpacity: root.fadeCoverOpacity,
        fadeCoverDuration: root.fadeCoverDuration,
        fadeRevealDelay: root.fadeRevealDelay,
        wallpaperLayerVisible: root.wallpaperLayerVisible,
        wallpaperFadeGateDelay: root.wallpaperFadeGateDelay,
        failureWatchdogDuration: root.failureWatchdogDuration,
        adaptiveReadinessTimeoutDuration: root.adaptiveReadinessTimeoutDuration,
        reducedMotion: root.reducedMotion,
        wallpaperPositionRefreshPending: root.wallpaperPositionRefreshPending,
        wallpaperPositionRefreshKey: root.wallpaperPositionRefreshKey,
        exitTransitionActive: root.exitTransitionActive,
        clearingWallpaperAfterExit: root.clearingWallpaperAfterExit,
        activeStartPosition: root.activeStartPosition,
        targetOutput: root.targetOutput,
        mediaRestartAttempts: root.mediaRestartAttempts,
        resolveRetryAttempts: root.resolveRetryAttempts,
        wallpaperRecoveryAttempts: root.wallpaperRecoveryAttempts,
        backend: "qml-framed-video"
      })
    }
  }

  IpcHandler {
    target: "lacuna-youtube-music-video"

    function status(): string {
      return mediaPlayerVideoIpc.status()
    }
  }
}
