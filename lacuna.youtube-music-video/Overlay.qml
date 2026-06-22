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
  readonly property bool usingHighRes: highResVideoSource !== "" && videoSource === highResVideoSource
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
  property int lastExitCode: 0
  property int restartAttempts: 0
  property bool fadeCoverVisible: false
  property real fadeCoverOpacity: 0
  property double fadeCoverStartedAt: 0
  property int fadeRevealDelay: 0
  property bool fadeCoverRising: false
  property int fadeCoverDuration: fadeInDuration
  property bool exitTransitionActive: false
  property bool clearingWallpaperAfterExit: false
  property int wallpaperFadeGateDelay: 0
  property bool wallpaperPositionRefreshPending: false
  property string wallpaperPositionRefreshKey: ""
  property int backgroundReadyProbeAttempts: 0
  readonly property bool wallpaperLayerVisible: wallpaperDesired || activeSource !== "" || exitTransitionActive

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
  onWaitingForHighResChanged: {
    if (waitingForHighRes) holdFadeCover()
  }
  onBackgroundRequestRevisionChanged: {
    if (service && service.backgroundVideoEnabled === true && service.playing === true && service.paused !== true) holdFadeCover()
  }
  onWallpaperDesiredChanged: syncWallpaper()
  onVideoSourceChanged: syncWallpaper()
  onBackgroundPlayingChanged: syncWallpaper()
  onStartPositionChanged: syncVideoPosition(false)

  function holdFadeCover() {
    exitTransitionActive = false
    clearingWallpaperAfterExit = false
    exitClearTimer.stop()
    fadeRevealTimer.stop()
    fadeHideTimer.stop()
    fadeCoverVisible = true
    fadeCoverStartedAt = Date.now()
    fadeCoverRising = true
    fadeCoverDuration = fadeInDuration
    fadeCoverOpacity = 1
  }

  function fadeInRemaining() {
    if (!fadeCoverRising || fadeCoverStartedAt <= 0) return 0
    return Math.max(0, fadeInDuration - (Date.now() - fadeCoverStartedAt))
  }

  function releaseFadeCoverSoon() {
    var elapsed = fadeCoverStartedAt > 0 ? Date.now() - fadeCoverStartedAt : fadeInDuration
    fadeRevealDelay = Math.max(500, fadeInDuration - elapsed)
    fadeRevealTimer.restart()
  }

  function releaseFadeCoverNow() {
    fadeRevealTimer.stop()
    fadeCoverRising = false
    fadeCoverDuration = clearingWallpaperAfterExit ? exitFadeFromBlackDuration : fadeOutDuration
    fadeCoverOpacity = 0
    fadeHideTimer.restart()
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
      holdFadeCover()
      wallpaperFadeGateDelay = fadeInDuration
      wallpaperFadeGateTimer.restart()
      return
    }

    var remainingFadeIn = fadeInRemaining()
    if (remainingFadeIn > 0) {
      wallpaperFadeGateDelay = Math.max(120, remainingFadeIn)
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
    activeStartPosition = Math.max(0, Math.floor(startPosition))
    syncVideoPosition(true)
    if (backgroundPlaying && fadeCoverOpacity > 0.01) releaseFadeCoverSoon()
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
    restartAttempts = 0
    wallpaperPositionRefreshPending = false
    wallpaperPositionRefreshKey = ""
    backgroundReadyProbeAttempts = 0
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
            if (playbackState !== MediaPlayer.StoppedState && root.fadeCoverOpacity > 0.01) root.releaseFadeCoverSoon()
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

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: fadeWindow

      required property var modelData
      readonly property bool targetMatched: root.outputMatches(modelData)
      readonly property var frameRect: root.resolveFrameRect(modelData)

      screen: modelData
      visible: targetMatched && root.fadeCoverVisible
      color: "transparent"
      implicitWidth: 0
      implicitHeight: 0
      WlrLayershell.namespace: "lacuna-youtube-music-video-fade"
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
        x: Math.round(fadeWindow.frameRect.x)
        y: Math.round(fadeWindow.frameRect.y)
        width: Math.round(fadeWindow.frameRect.width)
        height: Math.round(fadeWindow.frameRect.height)
        radius: Math.max(0, Number(fadeWindow.frameRect.radius || 0))
        color: "#000000"
        opacity: root.fadeCoverOpacity

        Behavior on opacity {
          NumberAnimation {
            duration: root.fadeCoverDuration
            easing.type: Easing.InOutQuad
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
    function onPreviewStreamUrlChanged() { root.syncWallpaper() }
    function onBackgroundStreamUrlChanged() { root.syncWallpaper() }
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
        backgroundRequestRevision: root.backgroundRequestRevision,
        waitingForHighRes: root.waitingForHighRes,
        fadeCoverVisible: root.fadeCoverVisible,
        fadeCoverOpacity: root.fadeCoverOpacity,
        fadeCoverDuration: root.fadeCoverDuration,
        fadeRevealDelay: root.fadeRevealDelay,
        wallpaperLayerVisible: root.wallpaperLayerVisible,
        wallpaperFadeGateDelay: root.wallpaperFadeGateDelay,
        wallpaperPositionRefreshPending: root.wallpaperPositionRefreshPending,
        wallpaperPositionRefreshKey: root.wallpaperPositionRefreshKey,
        exitTransitionActive: root.exitTransitionActive,
        clearingWallpaperAfterExit: root.clearingWallpaperAfterExit,
        backgroundReadyProbeAttempts: root.backgroundReadyProbeAttempts,
        usingHighRes: root.usingHighRes,
        source: root.videoSource,
        activeSource: root.activeSource,
        activeStartPosition: root.activeStartPosition,
        targetOutput: root.targetOutput,
        lastExitCode: root.lastExitCode,
        restartAttempts: root.restartAttempts,
        backend: "qml-framed-video"
      })
    }
  }
}
