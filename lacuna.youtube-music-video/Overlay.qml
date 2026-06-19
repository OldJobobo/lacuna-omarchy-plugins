import Quickshell
import Quickshell.Io
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
    && String(preferredVideoSource) !== ""
  readonly property bool backgroundPlaying: backgroundVisible && service.paused !== true
  readonly property string previewVideoSource: service ? String(service.previewStreamUrl || "") : ""
  readonly property string highResVideoSource: service ? String(service.backgroundStreamUrl || "") : ""
  readonly property string preferredVideoSource: highResVideoSource !== "" ? highResVideoSource : previewVideoSource
  readonly property bool usingHighRes: highResVideoSource !== "" && videoSource === highResVideoSource
  readonly property string videoSource: backgroundVisible ? preferredVideoSource : ""
  readonly property real startPosition: service && service.playbackPosition !== undefined ? Math.max(0, Number(service.playbackPosition) || 0) : 0
  readonly property bool wallpaperDesired: backgroundPlaying && videoSource !== ""
  property string activeSource: ""
  property var activeCommand: []
  property int activeStartPosition: 0
  property int lastExitCode: 0
  property int restartAttempts: 0
  property bool restartPending: false

  function wallpaperCommand(source, position) {
    return [
      "mpvpaper",
      "--layer",
      "background",
      "--mpv-options",
      "no-audio loop no-terminal hwdec=auto start=" + Math.max(0, Math.floor(position)),
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
  onWallpaperDesiredChanged: syncWallpaper()
  onVideoSourceChanged: syncWallpaper()

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
      return
    }

    if (wallpaperProcess.running && activeSource === videoSource) return

    if (wallpaperProcess.running) {
      restartPending = true
      wallpaperProcess.running = false
      return
    }

    activeSource = videoSource
    activeStartPosition = Math.max(0, Math.floor(startPosition))
    activeCommand = wallpaperCommand(activeSource, activeStartPosition)
    restartPending = false
    restartAttempts = 0
    wallpaperProcess.command = activeCommand
    wallpaperProcess.running = true
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
