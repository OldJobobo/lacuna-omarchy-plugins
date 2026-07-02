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

  readonly property string targetOutput: String(manifest && manifest.defaults && manifest.defaults.targetOutput ? manifest.defaults.targetOutput : "DP-1")
  readonly property bool allOutputs: targetOutput === "" || targetOutput === "ALL" || targetOutput === "*"
  readonly property bool backgroundVisible: service
    && service.backgroundVideoEnabled === true
    && String(highResVideoSource) !== ""
  readonly property bool backgroundPlaying: backgroundVisible && service.playing === true && service.paused !== true
  readonly property string highResVideoSource: service ? String(service.backgroundStreamUrl || "") : ""
  readonly property int backgroundRequestRevision: service && service.backgroundRequestRevision !== undefined ? Number(service.backgroundRequestRevision) || 0 : 0
  readonly property bool backgroundResolveFailed: service && service.backgroundResolveFailed === true
  readonly property string videoSource: backgroundVisible ? highResVideoSource : ""
  readonly property real startPosition: service && service.playbackPosition !== undefined ? Math.max(0, Number(service.playbackPosition) || 0) : 0
  readonly property bool wallpaperDesired: backgroundVisible && videoSource !== ""
  readonly property bool waitingForHighRes: service
    && service.backgroundVideoEnabled === true
    && service.playing === true
    && service.paused !== true
    && highResVideoSource === ""
  readonly property int fadeInDuration: 7000
  readonly property int fadeOutDuration: 7000
  readonly property int exitFadeToBlackDuration: 900
  readonly property int exitFadeFromBlackDuration: 1200
  property string activeSource: ""
  property int activeStartPosition: 0
  property int mediaRestartAttempts: 0
  property bool fadeCoverVisible: false
  property real fadeCoverOpacity: 0
  property double fadeCoverStartedAt: 0
  property double activeSourceAssignedAt: 0
  property int fadeRevealDelay: 0
  property bool fadeCoverRising: false
  property int fadeCoverDuration: fadeInDuration
  property bool exitTransitionActive: false
  property bool clearingWallpaperAfterExit: false
  property int wallpaperFadeGateDelay: 0
  property bool waitingForPlayerReady: false
  property bool wallpaperPositionRefreshPending: false
  property string wallpaperPositionRefreshKey: ""
  readonly property int mediaReadyMinimumHoldMs: 500
  readonly property int failureWatchdogDuration: 12000
  readonly property bool wallpaperLayerVisible: wallpaperDesired || activeSource !== "" || exitTransitionActive || fadeCoverVisible

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
      var ensured = root.shell.ensureService("lacuna.youtube-music")
      if (ensured) {
        root.service = ensured
        return
      }
    }
    if (root.shell && typeof root.shell.serviceFor === "function") {
      var existing = root.shell.serviceFor("lacuna.youtube-music")
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
  onWaitingForHighResChanged: if (waitingForHighRes) holdFadeCover(exitFadeToBlackDuration)
  onBackgroundRequestRevisionChanged: {
    if (service && service.backgroundVideoEnabled === true && service.playing === true && service.paused !== true) holdFadeCover(exitFadeToBlackDuration)
  }
  onBackgroundResolveFailedChanged: if (backgroundResolveFailed) giveUpWallpaper("resolve-failed")
  onWallpaperDesiredChanged: syncWallpaper()
  onVideoSourceChanged: syncWallpaper()
  onBackgroundPlayingChanged: syncWallpaper()
  onStartPositionChanged: syncVideoPosition(false)

  function holdFadeCover(duration) {
    exitTransitionActive = false
    clearingWallpaperAfterExit = false
    exitClearTimer.stop()
    fadeRevealTimer.stop()
    fadeHideTimer.stop()
    fadeCoverVisible = true
    fadeCoverStartedAt = Date.now()
    fadeCoverRising = true
    fadeCoverDuration = Math.max(1, Number(duration) || fadeInDuration)
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

  function notePlayerReady() {
    if (!waitingForPlayerReady || activeSource === "") return
    releaseFadeCoverSoon()
  }

  function notePlayerError(message) {
    if (activeSource === "") return
    if (mediaRestartAttempts <= 0 && service && typeof service.refreshBackgroundStream === "function") {
      mediaRestartAttempts += 1
      waitingForPlayerReady = true
      service.refreshBackgroundStream()
      failureWatchdog.restart()
      return
    }
    giveUpWallpaper(message || "player-error")
  }

  function giveUpWallpaper(reason) {
    wallpaperFadeGateTimer.stop()
    fadeRevealTimer.stop()
    waitingForPlayerReady = false
    activeSource = ""
    activeStartPosition = 0
    mediaRestartAttempts = 0
    wallpaperPositionRefreshPending = false
    wallpaperPositionRefreshKey = ""
    releaseFadeCoverNow()
  }

  function syncWallpaper() {
    if (!wallpaperDesired) {
      if (activeSource !== "" && !exitTransitionActive && !clearingWallpaperAfterExit) {
        beginWallpaperExit()
        return
      }
      if (!exitTransitionActive && !clearingWallpaperAfterExit) clearWallpaperNow()
      return
    }

    if (exitTransitionActive || clearingWallpaperAfterExit) {
      exitTransitionActive = false
      clearingWallpaperAfterExit = false
      exitClearTimer.stop()
    }

    if (activeSource !== videoSource && !fadeCoverRising && fadeCoverOpacity <= 0.001) {
      // Every appearance dips quickly to black and then reveals when the
      // player is actually ready — enabling the wallpaper feels the same as
      // a track change.
      holdFadeCover(exitFadeToBlackDuration)
      wallpaperFadeGateDelay = fadeCoverDuration
      wallpaperFadeGateTimer.restart()
      return
    }

    var remainingFadeCoverRise = fadeCoverRiseRemaining()
    if (remainingFadeCoverRise > 0) {
      wallpaperFadeGateDelay = Math.max(120, remainingFadeCoverRise)
      wallpaperFadeGateTimer.restart()
      return
    }

    var refreshKey = videoSource + "#" + backgroundRequestRevision
    if (wallpaperPositionRefreshKey !== refreshKey && !wallpaperPositionRefreshPending && service && typeof service.updatePlaybackPosition === "function") {
      wallpaperPositionRefreshPending = true
      service.updatePlaybackPosition()
      wallpaperPositionRefreshTimer.restart()
      return
    }

    activeSource = videoSource
    activeSourceAssignedAt = Date.now()
    activeStartPosition = Math.max(0, Math.floor(startPosition))
    waitingForPlayerReady = true
    mediaRestartAttempts = 0
    failureWatchdog.restart()
    syncVideoPosition(true)
  }

  function beginWallpaperExit() {
    wallpaperFadeGateTimer.stop()
    fadeRevealTimer.stop()
    fadeHideTimer.stop()
    exitTransitionActive = true
    clearingWallpaperAfterExit = false
    fadeCoverVisible = true
    fadeCoverRising = true
    fadeCoverStartedAt = Date.now()
    fadeCoverDuration = exitFadeToBlackDuration
    fadeCoverOpacity = 1
    exitClearTimer.restart()
  }

  function clearWallpaperNow() {
    activeSource = ""
    activeStartPosition = 0
    activeSourceAssignedAt = 0
    mediaRestartAttempts = 0
    waitingForPlayerReady = false
    wallpaperPositionRefreshPending = false
    wallpaperPositionRefreshKey = ""
    wallpaperFadeGateTimer.stop()
    if (!waitingForHighRes) releaseFadeCoverNow()
  }

  function syncVideoPosition(force) {
    for (var i = 0; i < videoPlayers.length; i++) {
      var player = videoPlayers[i]
      if (!player || player.source === "") continue
      var target = Math.max(0, Math.round(startPosition * 1000))
      if (force || Math.abs(player.position - target) > 900) player.setPosition(target)
    }
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
    interval: root.fadeCoverDuration + 400
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
    interval: root.exitFadeToBlackDuration + 80
    repeat: false
    onTriggered: {
      if (!root.exitTransitionActive || root.wallpaperDesired) return
      root.exitTransitionActive = false
      root.clearingWallpaperAfterExit = true
      root.clearWallpaperNow()
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
      if (root.waitingForHighRes || root.waitingForPlayerReady || root.backgroundResolveFailed) root.giveUpWallpaper("watchdog")
    }
  }

  Timer {
    id: wallpaperPositionRefreshTimer
    interval: 300
    repeat: false
    onTriggered: {
      root.wallpaperPositionRefreshKey = root.videoSource + "#" + root.backgroundRequestRevision
      root.wallpaperPositionRefreshPending = false
      root.syncWallpaper()
    }
  }

  Timer {
    interval: 1000
    repeat: true
    running: root.backgroundPlaying
    onTriggered: root.syncVideoPosition(false)
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
      visible: renderable
      color: "transparent"
      implicitWidth: 0
      implicitHeight: 0
      WlrLayershell.namespace: "lacuna-youtube-music-video"
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
            if (playbackState === MediaPlayer.PlayingState) root.notePlayerReady()
          }
          onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.BufferedMedia) root.notePlayerReady()
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
              root.syncVideoPosition(false)
              backgroundPlayer.play()
            } else {
              backgroundPlayer.pause()
            }
          }
          function onWallpaperDesiredChanged() {
            if (root.wallpaperDesired && root.backgroundPlaying && videoWindow.renderable) backgroundPlayer.play()
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
    function onBackgroundResolveFailedChanged() { if (root.backgroundResolveFailed) root.giveUpWallpaper("resolve-failed") }
    function onPlaybackPositionChanged() { root.syncVideoPosition(false) }
  }

  IpcHandler {
    target: "lacuna-youtube-music-video"

    function status(): string {
      return JSON.stringify({
        loaded: true,
        hasService: root.service !== null,
        backgroundVisible: root.backgroundVisible,
        backgroundPlaying: root.backgroundPlaying,
        wallpaperDesired: root.wallpaperDesired,
        wallpaperRunning: root.activeSource !== "",
        backgroundVideoEnabled: root.service && root.service.backgroundVideoEnabled === true,
        playing: root.service && root.service.playing === true,
        paused: root.service && root.service.paused === true,
        previewReady: root.service && String(root.service.previewStreamUrl || "") !== "",
        currentTrackUrl: root.service ? String(root.service.currentTrackUrl || "") : "",
        backgroundReady: root.service && String(root.service.backgroundStreamUrl || "") !== "",
        backgroundResolving: root.service && root.service.resolvingBackground === true,
        backgroundResolveFailed: root.backgroundResolveFailed,
        backgroundRequestRevision: root.backgroundRequestRevision,
        waitingForHighRes: root.waitingForHighRes,
        waitingForPlayerReady: root.waitingForPlayerReady,
        fadeCoverVisible: root.fadeCoverVisible,
        fadeCoverOpacity: root.fadeCoverOpacity,
        fadeCoverDuration: root.fadeCoverDuration,
        fadeRevealDelay: root.fadeRevealDelay,
        wallpaperLayerVisible: root.wallpaperLayerVisible,
        wallpaperFadeGateDelay: root.wallpaperFadeGateDelay,
        failureWatchdogDuration: root.failureWatchdogDuration,
        wallpaperPositionRefreshPending: root.wallpaperPositionRefreshPending,
        wallpaperPositionRefreshKey: root.wallpaperPositionRefreshKey,
        exitTransitionActive: root.exitTransitionActive,
        clearingWallpaperAfterExit: root.clearingWallpaperAfterExit,
        source: root.videoSource,
        activeSource: root.activeSource,
        activeStartPosition: root.activeStartPosition,
        targetOutput: root.targetOutput,
        mediaRestartAttempts: root.mediaRestartAttempts,
        backend: "qml-framed-video"
      })
    }
  }
}
