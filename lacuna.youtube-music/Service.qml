import Quickshell
import Quickshell.Io
import QtQuick

Item {
  id: root

  property string omarchyPath: ""
  property var shell: null
  property var manifest: null
  property var settings: ({})
  property bool mpvAvailable: false
  property bool ytdlpAvailable: false
  property bool searching: false
  property bool commandRunning: false
  property bool resolvingPreview: false
  property bool playing: false
  property bool paused: false
  property int volume: boundedInt(setting("volume", 70), 70, 0, 100)
  property string status: "checking"
  property string errorText: ""
  property var results: []
  property var queue: []
  property var currentTrack: null
  property string previewStreamUrl: ""

  readonly property bool available: mpvAvailable && ytdlpAvailable
  readonly property string sourceDir: manifest && manifest.__sourceDir ? manifest.__sourceDir : localPath(Qt.resolvedUrl("."))
  readonly property string checkScript: sourceDir + "/scripts/youtube-music-check"
  readonly property string searchScript: sourceDir + "/scripts/youtube-music-search"
  readonly property string controlScript: sourceDir + "/scripts/youtube-music-control"
  readonly property string previewScript: sourceDir + "/scripts/youtube-music-preview"
  readonly property string runtimeBase: Quickshell.env("XDG_RUNTIME_DIR") || (Quickshell.env("TMPDIR") || "/tmp")
  readonly property string runtimeDir: runtimeBase + "/lacuna-youtube-music"
  readonly property string mpvSocket: runtimeDir + "/mpv.sock"
  readonly property int maxResults: boundedInt(setting("maxResults", 8), 8, 3, 20)
  readonly property bool audioOnly: setting("audioOnly", true) !== false
  readonly property string displayTitle: currentTrack && currentTrack.title ? String(currentTrack.title) : ""
  readonly property string displaySubtitle: currentTrack && currentTrack.uploader ? String(currentTrack.uploader) : statusText()
  readonly property string thumbnail: currentTrack && currentTrack.thumbnail ? String(currentTrack.thumbnail) : ""
  readonly property string videoId: currentTrack && currentTrack.id ? String(currentTrack.id) : videoIdFromUrl(currentTrack && currentTrack.url ? String(currentTrack.url) : "")
  readonly property bool hasTrack: currentTrack !== null

  function localPath(url) {
    var value = String(url || "")
    if (value.indexOf("file://") === 0) value = value.slice(7)
    return decodeURIComponent(value)
  }

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function boundedInt(value, fallback, minimum, maximum) {
    var parsed = Math.round(Number(value))
    if (!isFinite(parsed)) return fallback
    return Math.max(minimum, Math.min(maximum, parsed))
  }

  function clampVolume(value) {
    return boundedInt(value, volume, 0, 100)
  }

  function statusText() {
    if (!mpvAvailable && !ytdlpAvailable) return "mpv and yt-dlp missing"
    if (!mpvAvailable) return "mpv missing"
    if (!ytdlpAvailable) return "yt-dlp missing"
    if (searching) return "Searching"
    if (playing && paused) return "Paused"
    if (playing) return "Playing"
    if (hasTrack) return "Stopped"
    return "Ready"
  }

  function trackUrl(track) {
    if (!track) return ""
    if (track.url) return String(track.url)
    if (track.webpage_url) return String(track.webpage_url)
    if (track.id) return "https://www.youtube.com/watch?v=" + String(track.id)
    return ""
  }

  function videoIdFromUrl(url) {
    var value = String(url || "")
    var match = value.match(/[?&]v=([^&#]+)/)
    if (match && match[1]) return decodeURIComponent(match[1])
    match = value.match(/youtu\.be\/([^?&#/]+)/)
    if (match && match[1]) return decodeURIComponent(match[1])
    match = value.match(/youtube\.com\/embed\/([^?&#/]+)/)
    if (match && match[1]) return decodeURIComponent(match[1])
    return ""
  }

  function trackThumbnail(track) {
    if (track && track.id) return "https://i.ytimg.com/vi/" + String(track.id) + "/hqdefault.jpg"
    return track && track.thumbnail ? String(track.thumbnail) : ""
  }

  function normalizeTrack(track) {
    if (!track || typeof track !== "object") return null
    var url = trackUrl(track)
    if (url === "") return null
    return {
      id: String(track.id || ""),
      title: String(track.title || "Untitled video"),
      uploader: String(track.uploader || track.channel || ""),
      duration: String(track.durationText || track.duration_text || ""),
      thumbnail: trackThumbnail(track),
      url: url
    }
  }

  function refreshDependencies() {
    checkProc.output = ""
    checkProc.command = [checkScript]
    checkProc.running = true
  }

  function search(query) {
    var trimmed = String(query || "").trim()
    if (trimmed === "") return
    if (!ytdlpAvailable) {
      errorText = "yt-dlp is required for search"
      status = "unavailable"
      return
    }
    searching = true
    errorText = ""
    searchProc.output = ""
    searchProc.command = [searchScript, "--limit", String(maxResults), trimmed]
    searchProc.running = true
  }

  function playNow(track) {
    var normalized = normalizeTrack(track)
    if (!normalized) return
    currentTrack = normalized
    previewStreamUrl = ""
    paused = false
    errorText = ""
    resolvePreview(normalized)
    startMpv(normalized)
  }

  function resolvePreview(track) {
    var url = trackUrl(track)
    if (url === "") return
    resolvingPreview = true
    previewProc.output = ""
    previewProc.command = [previewScript, url]
    previewProc.running = true
  }

  function addNext(track) {
    var normalized = normalizeTrack(track)
    if (!normalized) return
    var next = queue.slice()
    next.splice(0, 0, normalized)
    queue = next
  }

  function addToQueue(track) {
    var normalized = normalizeTrack(track)
    if (!normalized) return
    var next = queue.slice()
    next.push(normalized)
    queue = next
  }

  function removeQueued(index) {
    var idx = Math.round(Number(index))
    if (!isFinite(idx) || idx < 0 || idx >= queue.length) return
    var next = queue.slice()
    next.splice(idx, 1)
    queue = next
  }

  function clearQueue() {
    queue = []
  }

  function cleanupPlayback() {
    cleanupProc.command = [controlScript, "cleanup", "--socket", mpvSocket]
    cleanupProc.running = true
    playing = false
    paused = false
    status = statusText()
  }

  function next() {
    if (queue.length <= 0) {
      stop()
      return
    }
    var nextQueue = queue.slice()
    var track = nextQueue.shift()
    queue = nextQueue
    playNow(track)
  }

  function previousOrRestart() {
    if (!hasTrack) return
    sendCommand(["seek", 0, "absolute"])
  }

  function togglePause() {
    if (!playing) {
      if (hasTrack) startMpv(currentTrack)
      else if (queue.length > 0) next()
      return
    }
    sendCommand(["cycle", "pause"])
    paused = !paused
    status = statusText()
  }

  function seek(seconds) {
    if (!playing) return
    sendCommand(["seek", Number(seconds) || 0, "relative"])
  }

  function setVolume(value) {
    volume = clampVolume(value)
    if (playing) sendCommand(["set_property", "volume", volume])
  }

  function adjustVolume(delta) {
    setVolume(volume + Number(delta || 0))
  }

  function stop() {
    sendCommand(["quit"])
    playing = false
    paused = false
    status = statusText()
  }

  function startMpv(track) {
    if (!mpvAvailable) {
      errorText = "mpv is required for playback"
      status = "unavailable"
      return
    }
    var url = trackUrl(track)
    if (url === "") return

    commandProc.output = ""
    commandProc.command = [controlScript, "start", "--socket", mpvSocket, "--runtime-dir", runtimeDir, "--url", url, "--volume", String(volume), audioOnly ? "--audio-only" : "--video"]
    commandProc.running = true
    commandRunning = true
    playing = true
    paused = false
    status = "playing"
  }

  function sendCommand(command) {
    if (!command || command.length <= 0) return
    commandProc.output = ""
    commandProc.command = [controlScript, "command", "--socket", mpvSocket, "--payload", JSON.stringify({ command: command })]
    commandProc.running = true
    commandRunning = true
  }

  Component.onCompleted: {
    cleanupPlayback()
    refreshDependencies()
  }
  Component.onDestruction: stop()

  Process {
    id: checkProc
    property string output: ""

    stdout: SplitParser {
      onRead: function(data) { checkProc.output += data }
    }

    onExited: function(exitCode) {
      try {
        var payload = JSON.parse(checkProc.output || "{}")
        root.mpvAvailable = payload.mpv === true
        root.ytdlpAvailable = payload.ytdlp === true
        root.errorText = payload.message || ""
      } catch (e) {
        root.mpvAvailable = false
        root.ytdlpAvailable = false
        root.errorText = "Dependency check failed"
      }
      root.status = root.available ? "ready" : "unavailable"
    }
  }

  Process {
    id: searchProc
    property string output: ""

    stdout: SplitParser {
      onRead: function(data) { searchProc.output += data }
    }

    onExited: function(exitCode) {
      root.searching = false
      try {
        var payload = JSON.parse(searchProc.output || "{}")
        root.results = Array.isArray(payload.results) ? payload.results : []
        root.errorText = payload.error || ""
        root.status = root.errorText === "" ? "ready" : "error"
      } catch (e) {
        root.results = []
        root.errorText = "Search failed"
        root.status = "error"
      }
    }
  }

  Process {
    id: previewProc
    property string output: ""

    stdout: SplitParser {
      onRead: function(data) { previewProc.output += data }
    }

    onExited: function(exitCode) {
      root.resolvingPreview = false
      if (exitCode !== 0) return
      try {
        var payload = JSON.parse(previewProc.output || "{}")
        root.previewStreamUrl = payload.url || ""
      } catch (e) {
        root.previewStreamUrl = ""
      }
    }
  }

  Process {
    id: commandProc
    property string output: ""

    stdout: SplitParser {
      onRead: function(data) { commandProc.output += data }
    }

    onExited: function(exitCode) {
      root.commandRunning = false
      if (exitCode !== 0 && commandProc.output.trim() !== "") {
        try {
          var payload = JSON.parse(commandProc.output)
          root.errorText = payload.error || "Playback command failed"
        } catch (e) {
          root.errorText = "Playback command failed"
        }
        root.status = "error"
      } else if (root.errorText === "") {
        root.status = root.statusText().toLowerCase()
      }
    }
  }

  Process {
    id: cleanupProc
  }

  IpcHandler {
    target: "lacuna-youtube-music"

    function status(): string {
      return JSON.stringify({
        available: root.available,
        mpv: root.mpvAvailable,
        ytdlp: root.ytdlpAvailable,
        status: root.status,
        error: root.errorText,
        title: root.displayTitle,
        volume: root.volume,
        queueLength: root.queue.length
      })
    }
  }
}
