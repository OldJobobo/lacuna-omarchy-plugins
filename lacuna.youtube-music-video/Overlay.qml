import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

Item {
  id: root

  property string omarchyPath: ""
  property var shell: null
  property var manifest: null
  property var service: null

  readonly property string targetOutput: String(manifest && manifest.defaults && manifest.defaults.targetOutput ? manifest.defaults.targetOutput : "DP-1")
  readonly property string cleanupPattern: "^/usr/bin/mpvpaper --layer background .* (" + regexEscape(targetOutput) + "|ALL) "
  readonly property bool backgroundVisible: service
    && service.backgroundVideoEnabled === true
    && String(highResVideoSource) !== ""
  readonly property bool backgroundPlaying: backgroundVisible && service.paused !== true
  readonly property string highResVideoSource: service ? String(service.backgroundStreamUrl || "") : ""
  readonly property int backgroundRequestRevision: service && service.backgroundRequestRevision !== undefined ? Number(service.backgroundRequestRevision) || 0 : 0
  readonly property bool usingHighRes: highResVideoSource !== "" && videoSource === highResVideoSource
  readonly property string videoSource: backgroundVisible ? highResVideoSource : ""
  readonly property real startPosition: service && service.playbackPosition !== undefined ? Math.max(0, Number(service.playbackPosition) || 0) : 0
  readonly property bool wallpaperDesired: backgroundPlaying && videoSource !== ""
  readonly property bool waitingForHighRes: service
    && service.backgroundVideoEnabled === true
    && service.playing === true
    && service.paused !== true
    && highResVideoSource === ""
  readonly property int fadeInDuration: 7000
  readonly property int fadeOutDuration: 7000
  property string activeSource: ""
  property var activeCommand: []
  property int activeStartPosition: 0
  property int lastExitCode: 0
  property int restartAttempts: 0
  property bool restartPending: false
  property bool fadeCoverVisible: false
  property real fadeCoverOpacity: 0
  property double fadeCoverStartedAt: 0
  property int fadeRevealDelay: 0
  property bool fadeCoverRising: false
  property int wallpaperFadeGateDelay: 0

  function wallpaperCommand(source, position) {
    return [
      "mpvpaper",
      "--layer",
      "background",
      "--mpv-options",
      "no-audio loop no-terminal hwdec=auto panscan=1 start=" + Math.max(0, Math.floor(position)),
      targetOutput,
      source
    ]
  }

  function regexEscape(value) {
    return String(value || "").replace(/[.*+?^${}()|[\]\\]/g, "\\$&")
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
    startupCleanupTimer.restart()
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

  function holdFadeCover() {
    fadeRevealTimer.stop()
    fadeHideTimer.stop()
    fadeCoverVisible = true
    fadeCoverStartedAt = Date.now()
    fadeCoverRising = true
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
    fadeCoverOpacity = 0
    fadeHideTimer.restart()
  }

  function cleanupWallpaperProcess() {
    if (!cleanupProcess.running) cleanupProcess.running = true
  }

  function syncWallpaper() {
    if (!wallpaperDesired) {
      var hadActiveWallpaper = wallpaperProcess.running || activeSource !== ""
      restartPending = false
      activeSource = ""
      activeCommand = []
      activeStartPosition = 0
      restartAttempts = 0
      wallpaperProcess.running = false
      if (hadActiveWallpaper) cleanupWallpaperProcess()
      restartTimer.stop()
      wallpaperFadeGateTimer.stop()
      if (!waitingForHighRes) releaseFadeCoverNow()
      return
    }

    if (wallpaperProcess.running && activeSource === videoSource) return

    if (wallpaperProcess.running) {
      restartPending = true
      wallpaperProcess.running = false
      return
    }

    var remainingFadeIn = fadeInRemaining()
    if (remainingFadeIn > 0) {
      wallpaperFadeGateDelay = Math.max(120, remainingFadeIn)
      wallpaperFadeGateTimer.restart()
      return
    }

    activeSource = videoSource
    activeStartPosition = Math.max(0, Math.floor(startPosition))
    activeCommand = wallpaperCommand(activeSource, activeStartPosition)
    restartPending = false
    restartAttempts = 0
    wallpaperProcess.command = activeCommand
    wallpaperProcess.running = true
    if (fadeCoverOpacity > 0.01) releaseFadeCoverSoon()
  }

  Component.onDestruction: {
    wallpaperProcess.running = false
    cleanupWallpaperProcess()
  }

  Timer {
    interval: 500
    repeat: true
    running: root.service === null
    onTriggered: root.resolveService()
  }

  Timer {
    id: restartTimer
    interval: 120
    repeat: false
    onTriggered: root.syncWallpaper()
  }

  Timer {
    id: startupCleanupTimer
    interval: 900
    repeat: false
    onTriggered: {
      if (!root.wallpaperDesired && !wallpaperProcess.running) root.cleanupWallpaperProcess()
    }
  }

  Timer {
    id: fadeRevealTimer
    interval: root.fadeRevealDelay
    repeat: false
    onTriggered: root.releaseFadeCoverNow()
  }

  Timer {
    id: fadeHideTimer
    interval: root.fadeOutDuration + 400
    repeat: false
    onTriggered: if (root.fadeCoverOpacity <= 0.001) root.fadeCoverVisible = false
  }

  Timer {
    id: wallpaperFadeGateTimer
    interval: root.wallpaperFadeGateDelay
    repeat: false
    onTriggered: root.syncWallpaper()
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: fadeWindow

      required property var modelData

      screen: modelData
      visible: true
      color: "transparent"
      implicitWidth: 0
      implicitHeight: 0
      WlrLayershell.namespace: "lacuna-youtube-music-video-fade"
      WlrLayershell.layer: WlrLayer.Bottom
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
        anchors.fill: parent
        color: "#000000"
        opacity: root.fadeCoverOpacity

        Behavior on opacity {
          NumberAnimation {
            duration: root.fadeCoverOpacity > 0 ? root.fadeInDuration : root.fadeOutDuration
            easing.type: Easing.InOutQuad
          }
        }
      }
    }
  }

  Process {
    id: wallpaperProcess

    command: root.activeCommand
    running: false
    onExited: function(exitCode) {
      root.lastExitCode = exitCode
      if (root.restartPending || (root.wallpaperDesired && root.activeSource !== root.videoSource)) {
        root.restartPending = false
        restartTimer.restart()
      } else if (root.wallpaperDesired && root.activeSource === root.videoSource && root.restartAttempts < 3) {
        root.restartAttempts += 1
        root.activeSource = ""
        restartTimer.restart()
      }
    }
  }

  Process {
    id: cleanupProcess

    command: ["pkill", "-f", root.cleanupPattern]
    running: false
  }

  Connections {
    target: root.service

    function onBackgroundVideoEnabledChanged() { root.syncWallpaper() }
    function onPausedChanged() { root.syncWallpaper() }
    function onPlayingChanged() { root.syncWallpaper() }
    function onPreviewStreamUrlChanged() { root.syncWallpaper() }
    function onBackgroundStreamUrlChanged() { root.syncWallpaper() }
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
        wallpaperRunning: wallpaperProcess.running,
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
        fadeRevealDelay: root.fadeRevealDelay,
        wallpaperFadeGateDelay: root.wallpaperFadeGateDelay,
        usingHighRes: root.usingHighRes,
        source: root.videoSource,
        activeSource: root.activeSource,
        activeStartPosition: root.activeStartPosition,
        targetOutput: root.targetOutput,
        lastExitCode: root.lastExitCode,
        restartAttempts: root.restartAttempts,
        backend: "mpvpaper"
      })
    }
  }
}
