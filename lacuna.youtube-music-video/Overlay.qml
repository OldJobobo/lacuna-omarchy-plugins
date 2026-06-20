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
  readonly property string safeOutputId: targetOutput.replace(/[^A-Za-z0-9_.-]/g, "_")
  readonly property string backgroundSocket: service && service.runtimeDir ? String(service.runtimeDir) + "/mpvpaper-" + safeOutputId + ".sock" : ""
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
  readonly property bool wallpaperDesired: backgroundVisible && videoSource !== ""
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
  property bool wallpaperPositionRefreshPending: false
  property string wallpaperPositionRefreshKey: ""
  property int backgroundReadyProbeAttempts: 0

  function wallpaperCommand(source, position) {
    return [
      "mpvpaper",
      "--layer",
      "background",
      "--mpv-options",
      "no-terminal hwdec=auto panscan=1 input-ipc-server=" + backgroundSocket + " start=" + Math.max(0, Math.floor(position)) + " volume=" + Math.max(0, Math.min(100, service && service.volume !== undefined ? Number(service.volume) || 0 : 70)),
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
    if (service && service.controlScript && backgroundSocket !== "" && !backgroundSocketCleanupProcess.running) {
      backgroundSocketCleanupProcess.command = [service.controlScript, "cleanup", "--socket", backgroundSocket]
      backgroundSocketCleanupProcess.running = true
    }
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
      wallpaperPositionRefreshPending = false
      wallpaperPositionRefreshKey = ""
      backgroundReadyProbeAttempts = 0
      if (service && typeof service.releaseBackgroundPlayback === "function") service.releaseBackgroundPlayback()
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

    var refreshKey = videoSource + "#" + backgroundRequestRevision
    if (wallpaperPositionRefreshKey !== refreshKey && !wallpaperPositionRefreshPending && service && typeof service.updatePlaybackPosition === "function") {
      wallpaperPositionRefreshPending = true
      service.updatePlaybackPosition()
      wallpaperPositionRefreshTimer.restart()
      return
    }

    activeSource = videoSource
    activeStartPosition = Math.max(0, Math.floor(startPosition))
    activeCommand = wallpaperCommand(activeSource, activeStartPosition)
    restartPending = false
    restartAttempts = 0
    wallpaperProcess.command = activeCommand
    wallpaperProcess.running = true
    backgroundReadyProbeAttempts = 0
    backgroundAdoptTimer.restart()
    backgroundSyncDelayTimer.restart()
  }

  function syncBackgroundPlaybackPosition() {
    if (!service || !wallpaperProcess.running || !backgroundPlaying || backgroundSocket === "" || !service.controlScript) return
    if (backgroundPositionProcess.running || backgroundSeekProcess.running) return
    backgroundPositionProcess.output = ""
    backgroundPositionProcess.command = [service.controlScript, "get-property", "--socket", backgroundSocket, "--name", "time-pos"]
    backgroundPositionProcess.running = true
  }

  function restartBackgroundPlayback() {
    if (!wallpaperDesired || activeSource === "") return
    if (restartAttempts >= 3) {
      if (service) {
        service.backgroundOwnsAudio = false
        service.backgroundPlaybackSocket = ""
      }
      return
    }
    restartAttempts += 1
    if (service) {
      service.backgroundOwnsAudio = false
      service.backgroundPlaybackSocket = ""
    }
    holdFadeCover()
    restartPending = true
    wallpaperProcess.running = false
    cleanupWallpaperProcess()
    restartTimer.restart()
  }

  function tryAdoptBackgroundPlayback() {
    if (!service || !wallpaperProcess.running || !backgroundPlaying || backgroundSocket === "" || !service.controlScript) return
    if (backgroundOwnsAudioProbeProcess.running || service.backgroundOwnsAudio === true) return
    backgroundOwnsAudioProbeProcess.output = ""
    backgroundOwnsAudioProbeProcess.command = [service.controlScript, "get-property", "--socket", backgroundSocket, "--name", "vo-configured"]
    backgroundOwnsAudioProbeProcess.running = true
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
    id: backgroundSyncDelayTimer
    interval: 1200
    repeat: false
    onTriggered: root.syncBackgroundPlaybackPosition()
  }

  Timer {
    id: backgroundAdoptTimer
    interval: 500
    repeat: false
    onTriggered: root.tryAdoptBackgroundPlayback()
  }

  Timer {
    interval: 1000
    repeat: true
    running: root.wallpaperProcess.running && root.backgroundPlaying
    onTriggered: root.syncBackgroundPlaybackPosition()
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
      } else if (root.wallpaperDesired && root.activeSource === root.videoSource && exitCode === 0 && root.service && root.service.backgroundOwnsAudio === true) {
        root.activeSource = ""
        root.service.backgroundOwnsAudio = false
        root.service.backgroundPlaybackSocket = ""
        if (typeof root.service.handlePlaybackEnded === "function") root.service.handlePlaybackEnded()
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

  Process {
    id: backgroundSocketCleanupProcess
  }

  Process {
    id: backgroundOwnsAudioProbeProcess
    property string output: ""

    stdout: SplitParser {
      onRead: function(data) { backgroundOwnsAudioProbeProcess.output += data }
    }

    onExited: function(exitCode) {
      if (!root.backgroundPlaying || !root.service) return
      if (exitCode !== 0) {
        if (root.wallpaperProcess.running && root.backgroundReadyProbeAttempts < 20) {
          root.backgroundReadyProbeAttempts += 1
          backgroundAdoptTimer.restart()
        }
        return
      }
      try {
        var payload = JSON.parse(backgroundOwnsAudioProbeProcess.output || "{}")
        if (payload.value === true && typeof root.service.adoptBackgroundPlayback === "function") {
          root.service.adoptBackgroundPlayback(root.backgroundSocket)
          if (root.fadeCoverOpacity > 0.01) root.releaseFadeCoverSoon()
          return
        }
      } catch (error) {
      }
      if (root.wallpaperProcess.running && root.backgroundReadyProbeAttempts < 20) {
        root.backgroundReadyProbeAttempts += 1
        backgroundAdoptTimer.restart()
      }
    }
  }

  Process {
    id: backgroundPositionProcess
    property string output: ""

    stdout: SplitParser {
      onRead: function(data) { backgroundPositionProcess.output += data }
    }

    onExited: function(exitCode) {
      if (!root.backgroundPlaying) return
      if (exitCode !== 0) {
        root.restartBackgroundPlayback()
        return
      }
      try {
        var payload = JSON.parse(backgroundPositionProcess.output || "{}")
        var current = Number(payload.value)
        var target = root.startPosition
        if (!isFinite(current)) {
          root.restartBackgroundPlayback()
          return
        }
        if (isFinite(current) && isFinite(target) && Math.abs(current - target) > 0.45) {
          backgroundSeekProcess.command = [root.service.controlScript, "command", "--socket", root.backgroundSocket, "--payload", JSON.stringify({ command: ["seek", target, "absolute"] })]
          backgroundSeekProcess.running = true
        }
        if (isFinite(current) && current >= 0 && root.service && root.service.backgroundOwnsAudio !== true && typeof root.service.adoptBackgroundPlayback === "function") {
          root.service.adoptBackgroundPlayback(root.backgroundSocket)
          if (root.fadeCoverOpacity > 0.01) root.releaseFadeCoverSoon()
        }
      } catch (error) {
        root.restartBackgroundPlayback()
      }
    }
  }

  Process {
    id: backgroundSeekProcess
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
        wallpaperPositionRefreshPending: root.wallpaperPositionRefreshPending,
        wallpaperPositionRefreshKey: root.wallpaperPositionRefreshKey,
        backgroundReadyProbeAttempts: root.backgroundReadyProbeAttempts,
        backgroundSocket: root.backgroundSocket,
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
