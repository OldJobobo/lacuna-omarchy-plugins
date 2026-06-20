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
  property bool resolvingBackground: false
  property bool stateLoaded: false
  property bool loadingState: false
  property bool pendingBackgroundEnable: false
  property bool pendingDefaultSuggestions: false
  property bool backgroundOwnsAudio: false
  property int suppressStateReloads: 0
  property int playbackProbeFailures: 0
  property bool backgroundVideoEnabled: false
  property bool playing: false
  property bool paused: false
  property real playbackPosition: 0
  property int volume: boundedInt(setting("volume", 70), 70, 0, 100)
  property string status: "checking"
  property string errorText: ""
  property string lastQuery: ""
  property string repeatMode: "none"
  property var results: []
  property var allResults: []
  property var queue: []
  property var history: []
  property var favorites: []
  property int favoritesRevision: 0
  property var currentTrack: null
  property string previewStreamUrl: ""
  property string previewRequestUrl: ""
  property string backgroundStreamUrl: ""
  property string backgroundRequestUrl: ""
  property string backgroundPlaybackSocket: ""
  property int backgroundRequestRevision: 0

  readonly property bool available: mpvAvailable && ytdlpAvailable
  readonly property string sourceDir: manifest && manifest.__sourceDir ? manifest.__sourceDir : localPath(Qt.resolvedUrl("."))
  readonly property string checkScript: sourceDir + "/scripts/youtube-music-check"
  readonly property string searchScript: sourceDir + "/scripts/youtube-music-search"
  readonly property string controlScript: sourceDir + "/scripts/youtube-music-control"
  readonly property string previewScript: sourceDir + "/scripts/youtube-music-preview"
  readonly property string backgroundScript: sourceDir + "/scripts/youtube-music-background"
  readonly property string runtimeBase: Quickshell.env("XDG_RUNTIME_DIR") || (Quickshell.env("TMPDIR") || "/tmp")
  readonly property string runtimeDir: runtimeBase + "/lacuna-youtube-music"
  readonly property string mpvSocket: runtimeDir + "/mpv.sock"
  readonly property string configDir: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/omarchy/lacuna"
  readonly property string stateFile: configDir + "/youtube-music.json"
  readonly property int maxResults: boundedInt(setting("maxResults", 60), 60, 12, 80)
  readonly property string defaultSuggestionsQuery: String(setting("defaultSuggestionsQuery", "official music videos"))
  property int visibleLimit: 18
  readonly property bool canLoadMore: results.length < allResults.length
  readonly property bool audioOnly: setting("audioOnly", true) !== false
  readonly property string displayTitle: currentTrack && currentTrack.title ? String(currentTrack.title) : ""
  readonly property string displaySubtitle: currentTrack && currentTrack.uploader ? String(currentTrack.uploader) : statusText()
  readonly property string thumbnail: currentTrack && currentTrack.thumbnail ? String(currentTrack.thumbnail) : ""
  readonly property string currentTrackUrl: trackUrl(currentTrack)
  readonly property string videoId: currentTrack && currentTrack.id ? String(currentTrack.id) : videoIdFromUrl(currentTrack && currentTrack.url ? String(currentTrack.url) : "")
  readonly property bool hasTrack: currentTrack !== null
  readonly property int favoritesLength: favoritesRevision >= 0 ? favorites.length : 0
  readonly property bool currentFavorite: favoritesRevision >= 0 && isFavorite(currentTrack)

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
    match = value.match(/youtube\.com\/shorts\/([^?&#/]+)/)
    if (match && match[1]) return decodeURIComponent(match[1])
    return ""
  }

  function isYoutubeUrl(value) {
    var text = String(value || "").trim()
    return /^https?:\/\/(www\.)?(youtube\.com|music\.youtube\.com|youtu\.be)\//i.test(text)
  }

  function normalizeYoutubeUrl(value) {
    var text = String(value || "").trim()
    if (!isYoutubeUrl(text)) return ""
    var id = videoIdFromUrl(text)
    if (id !== "") return "https://www.youtube.com/watch?v=" + id
    return text
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

  function normalizeTrackList(rows, maximum) {
    var source = Array.isArray(rows) ? rows : []
    var next = []
    for (var i = 0; i < source.length && next.length < maximum; i++) {
      var track = normalizeTrack(source[i])
      if (track) next.push(track)
    }
    return next
  }

  function normalizeUniqueTrackList(rows, maximum) {
    var source = normalizeTrackList(rows, maximum)
    var seen = ({})
    var next = []
    for (var i = 0; i < source.length && next.length < maximum; i++) {
      var url = trackUrl(source[i])
      if (url === "" || seen[url] === true) continue
      seen[url] = true
      next.push(source[i])
    }
    return next
  }

  function normalizeRepeatMode(value) {
    var mode = String(value || "none")
    return mode === "one" || mode === "all" ? mode : "none"
  }

  function normalizeState(value) {
    var source = value && typeof value === "object" ? value : ({})
    return {
      version: 3,
      queue: normalizeTrackList(source.queue, 200),
      history: normalizeTrackList(source.history, 50),
      favorites: normalizeUniqueTrackList(source.favorites, 500),
      volume: boundedInt(source.volume, boundedInt(setting("volume", 70), 70, 0, 100), 0, 100),
      repeatMode: normalizeRepeatMode(source.repeatMode),
      lastQuery: String(source.lastQuery || "")
    }
  }

  function statePayload() {
    return JSON.stringify(normalizeState({
      queue: queue,
      history: history,
      favorites: favorites,
      volume: volume,
      repeatMode: repeatMode,
      lastQuery: lastQuery
    }), null, 2) + "\n"
  }

  function applyLoadedState(raw) {
    var parsed = {}
    try {
      parsed = JSON.parse(String(raw || "{}"))
    } catch (e) {
      console.warn("Lacuna YouTube music state is not valid JSON; restoring defaults:", e)
    }

    var restored = normalizeState(parsed)
    loadingState = true
    queue = restored.queue
    history = restored.history
    favorites = restored.favorites
    volume = restored.volume
    repeatMode = restored.repeatMode
    lastQuery = restored.lastQuery
    backgroundVideoEnabled = false
    loadingState = false
    stateLoaded = true
  }

  function saveStateNow() {
    if (!stateLoaded || loadingState) return
    suppressStateReloads += 1
    stateFileView.setText(statePayload())
  }

  function scheduleStateSave() {
    if (!stateLoaded || loadingState) return
    stateSaveTimer.restart()
  }

  function sameTrack(a, b) {
    return trackUrl(a) !== "" && trackUrl(a) === trackUrl(b)
  }

  function favoriteIndex(track) {
    var url = trackUrl(track)
    if (url === "") return -1
    for (var i = 0; i < favorites.length; i++) {
      if (trackUrl(favorites[i]) === url) return i
    }
    return -1
  }

  function isFavorite(track) {
    return favoriteIndex(track) >= 0
  }

  function favoriteTrack(track) {
    var normalized = normalizeTrack(track)
    if (!normalized || isFavorite(normalized)) return
    var next = favorites.slice()
    next.unshift(normalized)
    favorites = normalizeUniqueTrackList(next, 500)
  }

  function unfavoriteTrack(track) {
    var idx = favoriteIndex(track)
    if (idx < 0) return
    removeFavorite(idx)
  }

  function toggleFavorite(track) {
    if (isFavorite(track)) unfavoriteTrack(track)
    else favoriteTrack(track)
  }

  function playNormalized(normalized, rememberPrevious) {
    if (!normalized) return
    if (rememberPrevious && currentTrack && !sameTrack(currentTrack, normalized)) {
      var previous = history.slice()
      previous.push(currentTrack)
      if (previous.length > 50) previous.shift()
      history = previous
    }
    currentTrack = normalized
    previewStreamUrl = ""
    backgroundStreamUrl = ""
    playbackPosition = 0
    paused = false
    errorText = ""
    resolvePreview(normalized)
    if (backgroundVideoEnabled) resolveBackground(normalized)
    startMpv(normalized)
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
    lastQuery = trimmed
    visibleLimit = 18
    allResults = []
    results = []
    searchProc.output = ""
    searchProc.command = [searchScript, "--limit", String(maxResults), trimmed]
    searchProc.running = true
  }

  function loadDefaultSuggestions() {
    if (searching || allResults.length > 0) return
    if (!ytdlpAvailable) {
      pendingDefaultSuggestions = true
      return
    }
    pendingDefaultSuggestions = false
    search(defaultSuggestionsQuery)
  }

  function visibleSlice(rows) {
    return rows.slice(0, Math.min(visibleLimit, rows.length))
  }

  function setVisibleLimit(value) {
    visibleLimit = boundedInt(value, visibleLimit, 1, maxResults)
    results = visibleSlice(allResults)
  }

  function loadMore(count) {
    if (!canLoadMore) return
    setVisibleLimit(visibleLimit + boundedInt(count, 10, 1, 30))
  }

  function playNow(track) {
    var normalized = normalizeTrack(track)
    playNormalized(normalized, true)
  }

  function playUrl(url) {
    var normalizedUrl = normalizeYoutubeUrl(url)
    if (normalizedUrl === "") {
      errorText = "Paste a YouTube URL"
      status = "error"
      return
    }
    var id = videoIdFromUrl(normalizedUrl)
    playNow({
      id: id,
      title: id !== "" ? "YouTube video " + id : "YouTube video",
      uploader: "",
      duration: "",
      thumbnail: id !== "" ? "https://i.ytimg.com/vi/" + id + "/hqdefault.jpg" : "",
      url: normalizedUrl
    })
  }

  function resolvePreview(track) {
    var url = trackUrl(track)
    if (url === "") return
    previewRequestUrl = url
    previewStreamUrl = ""
    resolvingPreview = true
    previewStartTimer.restart()
  }

  function resolveBackground(track) {
    var url = trackUrl(track)
    if (url === "") return
    backgroundRequestUrl = url
    backgroundStreamUrl = ""
    resolvingBackground = true
    backgroundRequestRevision += 1
    backgroundStartTimer.restart()
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

  function moveQueued(index, delta) {
    var idx = Math.round(Number(index))
    var target = idx + Math.round(Number(delta))
    if (!isFinite(idx) || !isFinite(target) || idx < 0 || idx >= queue.length || target < 0 || target >= queue.length) return
    var next = queue.slice()
    var track = next.splice(idx, 1)[0]
    next.splice(target, 0, track)
    queue = next
  }

  function playQueued(index) {
    var idx = Math.round(Number(index))
    if (!isFinite(idx) || idx < 0 || idx >= queue.length) return
    var next = queue.slice()
    var track = next.splice(idx, 1)[0]
    queue = next
    playNow(track)
  }

  function clearQueue() {
    queue = []
  }

  function removeFavorite(index) {
    var idx = Math.round(Number(index))
    if (!isFinite(idx) || idx < 0 || idx >= favorites.length) return
    var next = favorites.slice()
    next.splice(idx, 1)
    favorites = next
  }

  function playFavorite(index) {
    var idx = Math.round(Number(index))
    if (!isFinite(idx) || idx < 0 || idx >= favorites.length) return
    playNow(favorites[idx])
  }

  function clearFavorites() {
    favorites = []
  }

  function setRepeatMode(mode) {
    repeatMode = normalizeRepeatMode(mode)
  }

  function cycleRepeatMode() {
    if (repeatMode === "none") repeatMode = "one"
    else if (repeatMode === "one") repeatMode = "all"
    else repeatMode = "none"
  }

  function cleanupPlayback() {
    cleanupProc.command = [controlScript, "cleanup", "--socket", mpvSocket]
    cleanupProc.running = true
    playing = false
    paused = false
    backgroundOwnsAudio = false
    backgroundPlaybackSocket = ""
    playbackPosition = 0
    playbackProbeFailures = 0
    status = statusText()
  }

  function playNextFromQueue(rememberPrevious, recycleCurrent) {
    if (queue.length <= 0) return false
    var nextQueue = queue.slice()
    var track = nextQueue.shift()
    if (recycleCurrent && currentTrack) nextQueue.push(currentTrack)
    queue = nextQueue
    playNormalized(track, rememberPrevious)
    return true
  }

  function next() {
    if (playNextFromQueue(true, false)) return
    if (repeatMode === "all" && currentTrack) {
      playNormalized(currentTrack, false)
      return
    }
    if (queue.length <= 0) {
      stop()
      return
    }
  }

  function handlePlaybackEnded() {
    playbackProbeFailures = 0

    if (repeatMode === "one" && currentTrack) {
      playNormalized(currentTrack, false)
      return
    }

    if (playNextFromQueue(true, repeatMode === "all")) return

    if (repeatMode === "all" && currentTrack) {
      playNormalized(currentTrack, false)
      return
    }

    stop()
  }

  function previousOrRestart() {
    if (!hasTrack) return
    if (history.length > 0) {
      var previous = history.slice()
      var track = previous.pop()
      history = previous
      if (currentTrack) {
        var nextQueue = queue.slice()
        nextQueue.unshift(currentTrack)
        queue = nextQueue
      }
      playNormalized(track, false)
      return
    }
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

  function setBackgroundVideoEnabled(enabled) {
    if (enabled === true) {
      if (hasTrack && (backgroundVideoEnabled || backgroundStreamUrl === "")) resolveBackground(currentTrack)
      if (backgroundVideoEnabled) {
        if (playing && !paused) updatePlaybackPosition()
        return
      }
      if (playing && !paused) {
        pendingBackgroundEnable = true
        if (!updatePlaybackPosition()) backgroundEnableFallback.restart()
        return
      }
      backgroundVideoEnabled = true
      return
    }
    pendingBackgroundEnable = false
    backgroundEnableFallback.stop()
    backgroundVideoEnabled = false
    resolvingBackground = false
    backgroundStreamUrl = ""
    backgroundRequestUrl = ""
    if (hasTrack && previewStreamUrl === "" && !resolvingPreview) resolvePreview(currentTrack)
  }

  function toggleBackgroundVideo() {
    setBackgroundVideoEnabled(!backgroundVideoEnabled)
  }

  function playbackSocket() {
    return backgroundOwnsAudio && backgroundPlaybackSocket !== "" ? backgroundPlaybackSocket : mpvSocket
  }

  function cleanupAudioOnlyPlayback() {
    if (!mpvAvailable || backgroundAudioCleanupProc.running) return
    backgroundAudioCleanupProc.command = [controlScript, "cleanup", "--socket", mpvSocket]
    backgroundAudioCleanupProc.running = true
  }

  function adoptBackgroundPlayback(socketPath) {
    var socket = String(socketPath || "")
    if (socket === "") return
    backgroundPlaybackSocket = socket
    backgroundOwnsAudio = true
    cleanupAudioOnlyPlayback()
    playbackProbeFailures = 0
    updatePlaybackPosition()
  }

  function releaseBackgroundPlayback() {
    if (!backgroundOwnsAudio) {
      backgroundPlaybackSocket = ""
      return
    }
    backgroundOwnsAudio = false
    backgroundPlaybackSocket = ""
    if (playing && !paused && hasTrack) startMpv(currentTrack, playbackPosition)
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
    pendingBackgroundEnable = false
    backgroundEnableFallback.stop()
    backgroundVideoEnabled = false
    backgroundOwnsAudio = false
    backgroundPlaybackSocket = ""
    backgroundStreamUrl = ""
    backgroundRequestUrl = ""
    playing = false
    paused = false
    resolvingPreview = false
    resolvingBackground = false
    status = statusText()
  }

  function startMpv(track, startAt) {
    if (!mpvAvailable) {
      errorText = "mpv is required for playback"
      status = "unavailable"
      return
    }
    var url = trackUrl(track)
    if (url === "") return

    commandProc.output = ""
    commandProc.command = [controlScript, "start", "--socket", mpvSocket, "--runtime-dir", runtimeDir, "--url", url, "--volume", String(volume), "--start", String(Math.max(0, Number(startAt) || 0)), audioOnly ? "--audio-only" : "--video"]
    commandProc.running = true
    commandRunning = true
    playing = true
    paused = false
    playbackPosition = Math.max(0, Number(startAt) || 0)
    playbackProbeFailures = 0
    status = "playing"
  }

  function sendCommand(command) {
    if (!command || command.length <= 0) return
    commandProc.output = ""
    commandProc.command = [controlScript, "command", "--socket", playbackSocket(), "--payload", JSON.stringify({ command: command })]
    commandProc.running = true
    commandRunning = true
  }

  Component.onCompleted: {
    cleanupPlayback()
    refreshDependencies()
    stateDirProc.running = true
  }
  Component.onDestruction: stop()

  onQueueChanged: scheduleStateSave()
  onHistoryChanged: scheduleStateSave()
  onFavoritesChanged: {
    favoritesRevision += 1
    scheduleStateSave()
  }
  onVolumeChanged: scheduleStateSave()
  onRepeatModeChanged: scheduleStateSave()
  onLastQueryChanged: scheduleStateSave()
  onBackgroundVideoEnabledChanged: if (backgroundVideoEnabled) updatePlaybackPosition()

  function updatePlaybackPosition() {
    if (!playing || paused || positionProc.running) return false
    positionProc.output = ""
    positionProc.command = [controlScript, "get-property", "--socket", playbackSocket(), "--name", "time-pos"]
    positionProc.running = true
    return true
  }

  Timer {
    id: stateSaveTimer
    interval: 350
    repeat: false
    onTriggered: root.saveStateNow()
  }

  Timer {
    id: previewStartTimer
    interval: 1
    repeat: false
    onTriggered: {
      if (!root.resolvingPreview || root.previewRequestUrl === "") return
      if (previewProc.running) {
        previewProc.running = false
        restart()
        return
      }
      previewProc.requestUrl = root.previewRequestUrl
      previewProc.output = ""
      previewProc.command = [previewScript, root.previewRequestUrl]
      previewProc.running = true
    }
  }

  Timer {
    id: backgroundStartTimer
    interval: 1
    repeat: false
    onTriggered: {
      if (!root.resolvingBackground || root.backgroundRequestUrl === "") return
      if (backgroundProc.running) {
        backgroundProc.running = false
        restart()
        return
      }
      backgroundProc.requestUrl = root.backgroundRequestUrl
      backgroundProc.output = ""
      backgroundProc.command = [backgroundScript, root.backgroundRequestUrl]
      backgroundProc.running = true
    }
  }

  Timer {
    interval: 1000
    repeat: true
    running: root.playing && !root.paused
    onTriggered: root.updatePlaybackPosition()
  }

  Timer {
    id: backgroundEnableFallback
    interval: 420
    repeat: false
    onTriggered: {
      if (root.pendingBackgroundEnable) {
        root.pendingBackgroundEnable = false
        root.backgroundVideoEnabled = true
      }
    }
  }

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
      if (root.pendingDefaultSuggestions && root.ytdlpAvailable) root.loadDefaultSuggestions()
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
        root.allResults = Array.isArray(payload.results) ? payload.results : []
        root.results = root.visibleSlice(root.allResults)
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
    property string requestUrl: ""

    stdout: SplitParser {
      onRead: function(data) { previewProc.output += data }
    }

    onExited: function(exitCode) {
      if (previewProc.requestUrl !== root.previewRequestUrl || previewProc.requestUrl !== root.trackUrl(root.currentTrack)) return
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
    id: backgroundProc
    property string output: ""
    property string requestUrl: ""

    stdout: SplitParser {
      onRead: function(data) { backgroundProc.output += data }
    }

    onExited: function(exitCode) {
      if (backgroundProc.requestUrl !== root.backgroundRequestUrl || backgroundProc.requestUrl !== root.trackUrl(root.currentTrack)) return
      root.resolvingBackground = false
      if (exitCode !== 0) return
      try {
        var payload = JSON.parse(backgroundProc.output || "{}")
        root.backgroundStreamUrl = payload.url || ""
      } catch (e) {
        root.backgroundStreamUrl = ""
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
    id: positionProc
    property string output: ""

    stdout: SplitParser {
      onRead: function(data) { positionProc.output += data }
    }

    onExited: function(exitCode) {
      if (exitCode !== 0) {
        if (root.pendingBackgroundEnable) backgroundEnableFallback.restart()
        else if (root.playing && !root.paused && !root.commandRunning) {
          root.playbackProbeFailures += 1
          if (root.playbackProbeFailures >= 2) root.handlePlaybackEnded()
        }
        return
      }
      root.playbackProbeFailures = 0
      try {
        var payload = JSON.parse(positionProc.output || "{}")
        var value = Number(payload.value)
        if (isFinite(value) && value >= 0) root.playbackPosition = value
      } catch (e) {
      }
      if (root.pendingBackgroundEnable) {
        root.pendingBackgroundEnable = false
        backgroundEnableFallback.stop()
        root.backgroundVideoEnabled = true
      }
    }
  }

  Process {
    id: cleanupProc
  }

  Process {
    id: backgroundAudioCleanupProc
  }

  Process {
    id: stateDirProc

    command: ["mkdir", "-p", root.configDir]
    onExited: stateFileView.reload()
  }

  FileView {
    id: stateFileView

    path: root.stateFile
    watchChanges: true
    atomicWrites: true
    printErrors: false
    onLoaded: root.applyLoadedState(text())
    onFileChanged: {
      if (root.suppressStateReloads > 0) {
        root.suppressStateReloads -= 1
      } else {
        reload()
      }
    }
    onLoadFailed: {
      root.applyLoadedState("{}")
      root.saveStateNow()
    }
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
        backgroundVideoEnabled: root.backgroundVideoEnabled,
        playing: root.playing,
        paused: root.paused,
        playbackPosition: root.playbackPosition,
        previewReady: root.previewStreamUrl !== "",
        previewResolving: root.resolvingPreview,
        previewUrl: root.previewStreamUrl,
        currentTrackUrl: root.currentTrackUrl,
        backgroundReady: root.backgroundStreamUrl !== "",
        backgroundResolving: root.resolvingBackground,
        backgroundUrl: root.backgroundStreamUrl,
        backgroundOwnsAudio: root.backgroundOwnsAudio,
        backgroundPlaybackSocket: root.backgroundPlaybackSocket,
        backgroundRequestRevision: root.backgroundRequestRevision,
        queueLength: root.queue.length,
        favoritesLength: root.favoritesLength,
        currentFavorite: root.currentFavorite,
        repeatMode: root.repeatMode
      })
    }

    function setBackgroundVideo(enabled: string): string {
      root.setBackgroundVideoEnabled(String(enabled || "").toLowerCase() === "true")
      return status()
    }

    function toggleBackgroundVideo(): string {
      root.toggleBackgroundVideo()
      return status()
    }

    function playPause(): string {
      root.togglePause()
      return status()
    }

    function playNext(): string {
      root.next()
      return status()
    }

    function toggleFavoriteCurrent(): string {
      root.toggleFavorite(root.currentTrack)
      return status()
    }

    function clearFavorites(): string {
      root.clearFavorites()
      return status()
    }

    function cycleRepeatMode(): string {
      root.cycleRepeatMode()
      return status()
    }
  }
}
