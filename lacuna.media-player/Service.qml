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
  property bool resolvingTrackInfo: false
  property bool refreshingFavorites: false
  property bool stateLoaded: false
  property bool loadingState: false
  property bool pendingBackgroundEnable: false
  property bool pendingDefaultSuggestions: false
  property bool backgroundOwnsAudio: false
  property int suppressStateReloads: 0
  property string lastWrittenStatePayload: ""
  property bool acceptNextStateReload: false
  property bool statePermissionChangePending: false
  property int playbackProbeFailures: 0
  property double playbackStartedAtMs: 0
  property real playbackDuration: 0
  property bool playbackEndHandled: false
  // Bumped whenever playback is (re)started, stopped, or failed, so probe
  // results issued against a previous mpv instance are discarded.
  property int playbackSessionRevision: 0
  // With --keep-open the eof probe is authoritative; the slack only covers the
  // fallback path where mpv exited and the last polled position must be judged
  // against the known duration (poll cadence is 1s).
  readonly property real endedProbeSlackSeconds: 3
  property var lacunaSettings: ({})
  property bool providerSearchActive: false
  property int searchRevision: 0
  property int pendingProviderSearches: 0
  property var providerSearchResults: ({ youtube: [], jellyfin: [] })
  property var providerSearchErrors: []
  property bool backgroundVideoEnabled: false
  property bool playing: false
  property bool paused: false
  property real playbackPosition: 0
  property int volume: boundedInt(setting("volume", 70), 70, 0, 100)
  property string status: "checking"
  property string errorText: ""
  property string lastQuery: ""
  property string searchFilter: "all"
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
  property string trackInfoRequestUrl: ""
  property string backgroundStreamUrl: ""
  property string backgroundRequestUrl: ""
  property string backgroundPlaybackSocket: ""
  property int backgroundRequestRevision: 0
  property bool backgroundResolveFailed: false
  property var streamUrlCache: ({})
  readonly property int streamUrlCacheTtlMs: 4 * 60 * 60 * 1000
  property var previewTelemetry: ({ loaded: false })
  property var pendingJellyfinTrack: null
  property real pendingJellyfinStartAt: 0

  readonly property bool available: mpvAvailable && (ytdlpAvailable || jellyfinConfigured)
  readonly property string sourceDir: manifest && manifest.__sourceDir ? manifest.__sourceDir : localPath(Qt.resolvedUrl("."))
  readonly property string checkScript: sourceDir + "/scripts/media-player-check"
  readonly property string searchScript: sourceDir + "/scripts/media-player-search"
  readonly property string authScript: sourceDir + "/scripts/youtube-auth"
  readonly property string infoScript: sourceDir + "/scripts/media-player-info"
  readonly property string refreshFavoritesScript: sourceDir + "/scripts/media-player-refresh-favorites"
  readonly property string controlScript: sourceDir + "/scripts/media-player-control"
  readonly property string previewScript: sourceDir + "/scripts/media-player-preview"
  readonly property string backgroundScript: sourceDir + "/scripts/media-player-background"
  readonly property string jellyfinSearchScript: sourceDir + "/scripts/jellyfin-search"
  readonly property string jellyfinStreamScript: sourceDir + "/scripts/jellyfin-stream"
  readonly property string runtimeBase: Quickshell.env("XDG_RUNTIME_DIR") || (Quickshell.env("TMPDIR") || "/tmp")
  readonly property string runtimeDir: runtimeBase + "/lacuna-media-player"
  readonly property string mpvSocket: runtimeDir + "/mpv.sock"
  readonly property string configDir: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/omarchy/lacuna"
  readonly property string stateFile: configDir + "/media-player.json"
  readonly property string legacyStateFile: configDir + "/youtube-music.json"
  readonly property string lacunaSettingsFile: configDir + "/settings.json"
  readonly property string youtubeAuthDir: configDir + "/youtube"
  readonly property string youtubeCookiesFile: youtubeAuthDir + "/cookies.txt"
  readonly property string youtubeConfigJson: JSON.stringify(youtubeProviderSettings())
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
  readonly property bool jellyfinConfigured: jellyfinConfigValue("enabled", false) === true
    && String(jellyfinConfigValue("serverUrl", "") || "").trim() !== ""
    && String(jellyfinConfigValue("apiKey", "") || "").trim() !== ""
  readonly property bool youtubeLoginEnabled: youtubeConfigValue("enabled", false) === true

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

  function updatePreviewTelemetry(payload) {
    previewTelemetry = payload && typeof payload === "object" ? payload : ({ loaded: false })
  }

  function streamCacheKey(trackOrUrl) {
    var url = typeof trackOrUrl === "string" ? String(trackOrUrl) : trackUrl(trackOrUrl)
    var id = videoIdFromUrl(url)
    return id !== "" ? id : url
  }

  function cachedStreamUrl(trackOrUrl) {
    var key = streamCacheKey(trackOrUrl)
    if (key === "") return ""
    var entry = streamUrlCache[key]
    if (!entry || !entry.url || Date.now() - Number(entry.resolvedAtMs || 0) > streamUrlCacheTtlMs) return ""
    return String(entry.url)
  }

  function rememberStreamUrl(trackOrUrl, url) {
    var key = streamCacheKey(trackOrUrl)
    var value = String(url || "")
    if (key === "" || value === "") return
    var next = Object.assign({}, streamUrlCache)
    next[key] = ({ url: value, resolvedAtMs: Date.now() })
    streamUrlCache = next
  }

  function statusText() {
    if (!mpvAvailable && !ytdlpAvailable && !jellyfinConfigured) return "mpv and yt-dlp missing"
    if (!mpvAvailable) return "mpv missing"
    if (!ytdlpAvailable && !jellyfinConfigured) return "yt-dlp missing"
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

  function jellyfinItemId(track) {
    if (!track || typeof track !== "object") return ""
    var direct = String(track.providerId || track.itemId || track.id || "")
    if (direct !== "") return direct
    var match = String(track.url || "").match(/\/Items\/([^/]+)\/Download/i)
    if (!match || !match[1]) return ""
    try {
      return decodeURIComponent(match[1])
    } catch (e) {
      return match[1]
    }
  }

  function stableJellyfinUrl(itemId) {
    var id = String(itemId || "")
    return id === "" ? "" : "jellyfin://item/" + encodeURIComponent(id)
  }

  function providerFor(track) {
    return track && track.provider ? String(track.provider) : "youtube"
  }

  function providerLabel(track) {
    var provider = providerFor(track)
    if (provider === "jellyfin") return "Jellyfin"
    return "YouTube"
  }

  function mediaTypeFor(track) {
    return track && track.mediaType ? String(track.mediaType) : "video"
  }

  function streamKindFor(track) {
    return track && track.streamKind ? String(track.streamKind) : (mediaTypeFor(track) === "audio" ? "audio" : "video")
  }

  function itemHasVideo(track) {
    return streamKindFor(track) === "video" || mediaTypeFor(track) !== "audio"
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
    if (providerFor(track) === "jellyfin") return track && track.thumbnail ? String(track.thumbnail) : ""
    if (track && track.id) return "https://i.ytimg.com/vi/" + String(track.id) + "/hqdefault.jpg"
    return track && track.thumbnail ? String(track.thumbnail) : ""
  }

  function normalizeTrack(track) {
    if (!track || typeof track !== "object") return null
    var url = trackUrl(track)
    var provider = String(track.provider || (isYoutubeUrl(url) ? "youtube" : "external"))
    var providerId = provider === "jellyfin" ? jellyfinItemId(track) : String(track.providerId || track.itemId || track.id || "")
    if (provider === "jellyfin") url = stableJellyfinUrl(providerId)
    if (url === "") return null
    var mediaType = String(track.mediaType || (provider === "jellyfin" ? "video" : "video"))
    var streamKind = String(track.streamKind || (mediaType === "audio" ? "audio" : "video"))
    var sourceLabel = String(track.source || providerLabel({ provider: provider }))
    return {
      id: String(track.id || ""),
      provider: provider,
      providerId: providerId,
      mediaType: mediaType,
      streamKind: streamKind,
      libraryName: String(track.libraryName || ""),
      title: String(track.title || "Untitled video"),
      uploader: String(track.uploader || track.channel || ""),
      duration: String(track.durationText || track.duration_text || ""),
      thumbnail: provider === "jellyfin" ? "" : trackThumbnail(track),
      source: sourceLabel,
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

  function loadLacunaSettings(raw) {
    try {
      lacunaSettings = JSON.parse(raw || "{}")
    } catch (e) {
      lacunaSettings = ({})
    }
  }

  function jellyfinProviderSettings() {
    var settings = lacunaSettings && typeof lacunaSettings === "object" ? lacunaSettings : ({})
    var providers = settings.mediaProviders && typeof settings.mediaProviders === "object" ? settings.mediaProviders : ({})
    var jellyfin = providers.jellyfin && typeof providers.jellyfin === "object" ? providers.jellyfin : ({})
    return {
      enabled: jellyfin.enabled === true,
      serverUrl: String(jellyfin.serverUrl || ""),
      apiKey: String(jellyfin.apiKey || ""),
      userId: String(jellyfin.userId || "")
    }
  }

  function youtubeProviderSettings() {
    var settings = lacunaSettings && typeof lacunaSettings === "object" ? lacunaSettings : ({})
    var providers = settings.mediaProviders && typeof settings.mediaProviders === "object" ? settings.mediaProviders : ({})
    var youtube = providers.youtube && typeof providers.youtube === "object" ? providers.youtube : ({})
    return {
      enabled: youtube.enabled === true,
      cookiesFromBrowser: String(youtube.cookiesFromBrowser || ""),
      cookiesFile: String(youtube.cookiesFile || ""),
      defaultSuggestionsQuery: defaultSuggestionsQuery
    }
  }

  function youtubeConfigValue(key, fallback) {
    var cfg = youtubeProviderSettings()
    return cfg[key] !== undefined ? cfg[key] : fallback
  }

  function jellyfinConfigValue(key, fallback) {
    var cfg = jellyfinProviderSettings()
    return cfg[key] !== undefined ? cfg[key] : fallback
  }

  function providerSearchLimit(provider) {
    if (provider === "jellyfin" && ytdlpAvailable) return Math.max(4, Math.ceil(maxResults / 2))
    return maxResults
  }

  function mergeProviderResults(primaryRows, secondaryRows, maximum) {
    var rows = []
    var seen = ({})
    var a = Array.isArray(primaryRows) ? primaryRows : []
    var b = Array.isArray(secondaryRows) ? secondaryRows : []
    var total = Math.max(a.length, b.length)
    for (var i = 0; i < total && rows.length < maximum; i++) {
      if (i < a.length) appendUniqueProviderResult(rows, seen, a[i], maximum)
      if (i < b.length) appendUniqueProviderResult(rows, seen, b[i], maximum)
    }
    return rows
  }

  function appendUniqueProviderResult(rows, seen, track, maximum) {
    var normalized = normalizeTrack(track)
    if (!normalized || rows.length >= maximum) return
    var key = providerFor(normalized) + ":" + trackUrl(normalized)
    if (seen[key] === true) return
    seen[key] = true
    rows.push(normalized)
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
    if (/api_key=|\/Items\/[^/]+\/Download\?/i.test(String(raw || ""))) scheduleStateSave()
  }

  function saveStateNow() {
    if (!stateLoaded || loadingState) return
    suppressStateReloads += 1
    lastWrittenStatePayload = statePayload()
    stateFileView.setText(lastWrittenStatePayload)
    secureStateFile()
  }

  function secureStateFile() {
    statePermissionsTimer.restart()
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
    backgroundResolveFailed = false
    if (!itemHasVideo(normalized)) {
      backgroundVideoEnabled = false
      pendingBackgroundEnable = false
    }
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

  function normalizeSearchFilter(value) {
    return String(value || "all") === "music" ? "music" : "all"
  }

  function search(query) {
    var trimmed = String(query || "").trim()
    if (trimmed === "") return
    if (!ytdlpAvailable && !jellyfinConfigured) {
      errorText = "yt-dlp is required for search"
      status = "unavailable"
      return
    }
    searching = true
    searchRevision += 1
    errorText = ""
    lastQuery = trimmed
    visibleLimit = 18
    allResults = []
    results = []
    if (jellyfinConfigured) {
      providerSearchActive = true
      pendingProviderSearches = ytdlpAvailable ? 2 : 1
      providerSearchResults = ({ youtube: [], jellyfin: [] })
      providerSearchErrors = []
      if (ytdlpAvailable) startYoutubeSearch(trimmed, providerSearchLimit("youtube"), searchRevision)
      startJellyfinSearch(trimmed, providerSearchLimit("jellyfin"), searchRevision)
      return
    }
    providerSearchActive = false
    startYoutubeSearch(trimmed, maxResults, searchRevision)
  }

  function startYoutubeSearch(query, limit, revision) {
    searchProc.pendingCommand = [searchScript, "--config-json", youtubeConfigJson, "--filter", searchFilter, "--limit", String(limit), query]
    searchProc.pendingRevision = revision
    if (searchProc.running) searchProc.running = false
    searchStartTimer.restart()
  }

  function startYoutubeSuggestions(limit, revision) {
    searchProc.pendingCommand = [searchScript, "--config-json", youtubeConfigJson, "--filter", searchFilter, "--limit", String(limit), "--suggestions"]
    searchProc.pendingRevision = revision
    if (searchProc.running) searchProc.running = false
    searchStartTimer.restart()
  }

  function startJellyfinSearch(query, limit, revision) {
    jellyfinSearchProc.pendingCommand = [jellyfinSearchScript, "--settings-file", lacunaSettingsFile, "--limit", String(limit), query]
    jellyfinSearchProc.pendingRevision = revision
    if (jellyfinSearchProc.running) jellyfinSearchProc.running = false
    jellyfinSearchStartTimer.restart()
  }

  function completeProviderSearch(provider, rows, error, revision) {
    if (revision !== searchRevision) return
    if (providerSearchResults && typeof providerSearchResults === "object") providerSearchResults[provider] = Array.isArray(rows) ? rows : []
    if (error && String(error) !== "") providerSearchErrors = providerSearchErrors.concat([providerLabel({ provider: provider }) + ": " + String(error)])
    pendingProviderSearches = Math.max(0, pendingProviderSearches - 1)
    if (pendingProviderSearches > 0) return

    providerSearchActive = false
    searching = false
    allResults = mergeProviderResults(providerSearchResults.youtube, providerSearchResults.jellyfin, maxResults)
    results = visibleSlice(allResults)
    errorText = providerSearchErrors.join(" / ")
    status = errorText === "" || allResults.length > 0 ? "ready" : "error"
  }

  function loadDefaultSuggestions() {
    if (searching || allResults.length > 0) return
    if (!ytdlpAvailable && !jellyfinConfigured) {
      pendingDefaultSuggestions = true
      return
    }
    pendingDefaultSuggestions = false
    searching = true
    searchRevision += 1
    errorText = ""
    lastQuery = ""
    visibleLimit = 18
    allResults = []
    results = []
    if (!ytdlpAvailable && jellyfinConfigured) {
      providerSearchActive = true
      pendingProviderSearches = 1
      providerSearchResults = ({ youtube: [], jellyfin: [] })
      providerSearchErrors = []
      startJellyfinSearch("", Math.min(maxResults, 24), searchRevision)
      return
    }
    providerSearchActive = false
    startYoutubeSuggestions(Math.min(maxResults, 24), searchRevision)
  }

  function refreshYoutubeResultsAfterLogin() {
    if (!youtubeLoginEnabled || searching) return
    var query = String(lastQuery || "").trim()
    allResults = []
    results = []
    visibleLimit = 18
    if (query !== "") search(query)
    else loadDefaultSuggestions()
  }

  function setSearchFilter(value) {
    var next = normalizeSearchFilter(value)
    if (searchFilter === next) return
    searchFilter = next
    var query = String(lastQuery || "").trim()
    allResults = []
    results = []
    visibleLimit = 18
    if (query !== "") search(query)
    else loadDefaultSuggestions()
  }

  function openYoutubeLogin() {
    authProc.command = [authScript, "--auth-dir", youtubeAuthDir]
    authProc.running = true
  }

  function openYoutubeMusicLogin() {
    openYoutubeLogin()
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
    resolveTrackInfo(currentTrack)
  }

  function resolveTrackInfo(track) {
    var url = trackUrl(track)
    if (url === "" || providerFor(track) !== "youtube") return
    trackInfoRequestUrl = url
    resolvingTrackInfo = true
    trackInfoStartTimer.restart()
  }

  function resolvePreview(track) {
    var url = trackUrl(track)
    if (url === "") return
    if (providerFor(track) === "jellyfin") {
      var jellyfinCached = cachedStreamUrl(track)
      previewStreamUrl = itemHasVideo(track) ? jellyfinCached : ""
      resolvingPreview = jellyfinCached === ""
      return
    }
    var cached = cachedStreamUrl(track)
    if (cached !== "") {
      previewRequestUrl = url
      previewStreamUrl = cached
      resolvingPreview = false
      if (backgroundVideoEnabled && backgroundStreamUrl === "") {
        backgroundRequestUrl = url
        backgroundStreamUrl = cached
        backgroundResolveFailed = false
        resolvingBackground = false
        backgroundRequestRevision += 1
      }
      return
    }
    previewRequestUrl = url
    previewStreamUrl = ""
    resolvingPreview = true
    previewStartTimer.restart()
  }

  function resolveBackground(track) {
    var url = trackUrl(track)
    if (url === "") return
    if (providerFor(track) === "jellyfin") {
      backgroundRequestUrl = url
      var jellyfinCached = cachedStreamUrl(track)
      backgroundStreamUrl = itemHasVideo(track) ? jellyfinCached : ""
      resolvingBackground = jellyfinCached === ""
      backgroundResolveFailed = false
      backgroundRequestRevision += 1
      return
    }
    var cached = cachedStreamUrl(track)
    if (cached !== "") {
      backgroundRequestUrl = url
      backgroundStreamUrl = cached
      backgroundResolveFailed = false
      resolvingBackground = false
      backgroundRequestRevision += 1
      return
    }
    backgroundRequestUrl = url
    backgroundStreamUrl = ""
    backgroundResolveFailed = false
    resolvingBackground = true
    backgroundRequestRevision += 1
    if (resolvingPreview && previewRequestUrl === url) return
    if (previewStreamUrl !== "") {
      rememberStreamUrl(track, previewStreamUrl)
      backgroundStreamUrl = previewStreamUrl
      resolvingBackground = false
      return
    }
    backgroundStartTimer.restart()
  }

  function refreshBackgroundStream() {
    if (!hasTrack) return
    var key = streamCacheKey(currentTrack)
    if (key !== "") {
      var next = Object.assign({}, streamUrlCache)
      delete next[key]
      streamUrlCache = next
    }
    backgroundStreamUrl = ""
    resolveBackground(currentTrack)
  }

  function prefetchNextBackground() {
    if (!backgroundVideoEnabled || queue.length <= 0) return
    var nextTrack = normalizeTrack(queue[0])
    if (!nextTrack || !itemHasVideo(nextTrack) || providerFor(nextTrack) !== "youtube") return
    if (cachedStreamUrl(nextTrack) !== "") return
    var url = trackUrl(nextTrack)
    if (url === "" || url === backgroundRequestUrl || backgroundPrefetchProc.running) return
    backgroundPrefetchProc.requestUrl = url
    backgroundPrefetchProc.output = ""
    backgroundPrefetchProc.command = [backgroundScript, "--config-json", youtubeConfigJson, url]
    backgroundPrefetchProc.running = true
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

  function refreshFavoriteMetadata() {
    if (refreshingFavorites || !ytdlpAvailable) return
    favoritesRefreshProc.output = ""
    favoritesRefreshProc.command = [refreshFavoritesScript, stateFile, infoScript]
    favoritesRefreshProc.running = true
    refreshingFavorites = true
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
    playbackDuration = 0
    playbackEndHandled = false
    playbackSessionRevision += 1
    playbackProbeFailures = 0
    status = statusText()
  }

  function markPlaybackFailed(message) {
    if (!cleanupProc.running) {
      cleanupProc.command = [controlScript, "cleanup", "--socket", playbackSocket()]
      cleanupProc.running = true
    }
    pendingBackgroundEnable = false
    backgroundEnableFallback.stop()
    backgroundOwnsAudio = false
    backgroundPlaybackSocket = ""
    playing = false
    paused = false
    playbackProbeFailures = 0
    playbackSessionRevision += 1
    errorText = message || "Playback stream unavailable"
    status = "error"
  }

  function notePlaybackProbeFailure() {
    if (pendingBackgroundEnable) {
      backgroundEnableFallback.restart()
      return
    }
    if (Date.now() - playbackStartedAtMs < 10000) return
    if (playing && !paused && !commandRunning) {
      playbackProbeFailures += 1
      if (playbackProbeFailures >= 2) markPlaybackFailed("Playback stream unavailable")
    }
  }

  function playbackLooksFinished() {
    if (!playing || paused) return false
    if (!(playbackDuration > 0)) return false
    return playbackPosition >= Math.max(0, playbackDuration - endedProbeSlackSeconds)
  }

  function notePlaybackEnded() {
    if (playbackEndHandled || !playing || paused) return
    playbackEndHandled = true
    playbackProbeFailures = 0
    if (playbackDuration > 0) playbackPosition = playbackDuration
    handlePlaybackEnded()
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
      if (hasTrack && !itemHasVideo(currentTrack)) {
        errorText = "Background video is unavailable for audio-only media"
        status = "error"
        return
      }
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
    backgroundResolveFailed = false
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
    if (playing) volumeCommandTimer.restart()
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
    backgroundResolveFailed = false
    playing = false
    paused = false
    playbackDuration = 0
    playbackEndHandled = false
    playbackSessionRevision += 1
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

    if (providerFor(track) === "jellyfin") {
      var cached = cachedStreamUrl(track)
      if (cached !== "") {
        applyJellyfinStream(track, cached)
        startMpvResolved(track, cached, startAt)
        return
      }
      pendingJellyfinTrack = track
      pendingJellyfinStartAt = Math.max(0, Number(startAt) || 0)
      if (!cleanupProc.running) {
        cleanupProc.command = [controlScript, "cleanup", "--socket", playbackSocket()]
        cleanupProc.running = true
      }
      playing = false
      paused = false
      if (jellyfinStreamProc.running) jellyfinStreamProc.running = false
      jellyfinStreamStartTimer.restart()
      commandRunning = true
      status = "loading"
      return
    }

    startMpvResolved(track, url, startAt)
  }

  function applyJellyfinStream(track, url) {
    if (!track || providerFor(track) !== "jellyfin" || String(url || "") === "") return
    rememberStreamUrl(track, url)
    resolvingPreview = false
    previewStreamUrl = itemHasVideo(track) ? url : ""
    if (backgroundVideoEnabled && itemHasVideo(track)) {
      resolvingBackground = false
      backgroundResolveFailed = false
      backgroundRequestUrl = trackUrl(track)
      backgroundStreamUrl = url
      backgroundRequestRevision += 1
    }
  }

  function startMpvResolved(track, url, startAt) {
    if (String(url || "") === "") return

    commandProc.output = ""
    var args = [controlScript, "start", "--socket", mpvSocket, "--runtime-dir", runtimeDir, "--url", url, "--volume", String(volume), "--start", String(Math.max(0, Number(startAt) || 0))]
    var youtubeConfig = youtubeProviderSettings()
    if (youtubeConfig.enabled === true && youtubeConfig.cookiesFile !== "") args.push("--cookies-file", youtubeConfig.cookiesFile)
    else if (youtubeConfig.enabled === true && youtubeConfig.cookiesFromBrowser !== "") args.push("--cookies-from-browser", youtubeConfig.cookiesFromBrowser)
    args.push(audioOnly ? "--audio-only" : "--video")
    commandProc.command = args
    commandProc.running = true
    commandRunning = true
    playing = true
    paused = false
    playbackPosition = Math.max(0, Number(startAt) || 0)
    playbackDuration = 0
    playbackEndHandled = false
    playbackSessionRevision += 1
    playbackStartedAtMs = Date.now()
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
    secureStateFile()
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
  onJellyfinConfiguredChanged: {
    if (pendingDefaultSuggestions && (ytdlpAvailable || jellyfinConfigured)) loadDefaultSuggestions()
    status = available ? "ready" : "unavailable"
  }
  onYoutubeLoginEnabledChanged: {
    if (youtubeLoginEnabled) refreshYoutubeResultsAfterLogin()
    else if (pendingDefaultSuggestions && (ytdlpAvailable || jellyfinConfigured)) loadDefaultSuggestions()
    status = available ? "ready" : "unavailable"
  }

  function updatePlaybackPosition() {
    if (!playing || paused || positionProc.running) return false
    positionProc.output = ""
    positionProc.sessionRevision = playbackSessionRevision
    positionProc.command = [controlScript, "probe", "--socket", playbackSocket()]
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
    id: volumeCommandTimer
    interval: 75
    repeat: false
    onTriggered: {
      if (!root.playing) return
      if (volumeProc.running) {
        restart()
        return
      }
      volumeProc.command = [root.controlScript, "command", "--socket", root.playbackSocket(), "--payload", JSON.stringify({ command: ["set_property", "volume", root.volume] })]
      volumeProc.running = true
    }
  }

  Timer {
    id: searchStartTimer
    interval: 5
    repeat: false
    onTriggered: {
      if (searchProc.running) {
        restart()
        return
      }
      searchProc.output = ""
      searchProc.requestRevision = searchProc.pendingRevision
      searchProc.command = searchProc.pendingCommand
      searchProc.running = true
    }
  }

  Timer {
    id: jellyfinSearchStartTimer
    interval: 5
    repeat: false
    onTriggered: {
      if (jellyfinSearchProc.running) {
        restart()
        return
      }
      jellyfinSearchProc.output = ""
      jellyfinSearchProc.requestRevision = jellyfinSearchProc.pendingRevision
      jellyfinSearchProc.command = jellyfinSearchProc.pendingCommand
      jellyfinSearchProc.running = true
    }
  }

  Timer {
    id: jellyfinStreamStartTimer
    interval: 5
    repeat: false
    onTriggered: {
      if (jellyfinStreamProc.running) {
        restart()
        return
      }
      var track = root.normalizeTrack(root.pendingJellyfinTrack)
      var itemId = root.jellyfinItemId(track)
      if (!track || itemId === "") {
        root.commandRunning = false
        root.errorText = "Jellyfin item is missing its provider ID"
        root.status = "error"
        return
      }
      jellyfinStreamProc.output = ""
      jellyfinStreamProc.requestUrl = root.trackUrl(track)
      jellyfinStreamProc.requestStartAt = root.pendingJellyfinStartAt
      jellyfinStreamProc.command = [root.jellyfinStreamScript, "--settings-file", root.lacunaSettingsFile, "--item-id", itemId, "--media-type", root.mediaTypeFor(track)]
      jellyfinStreamProc.running = true
    }
  }

  FileView {
    id: lacunaSettingsFileView

    path: root.lacunaSettingsFile
    watchChanges: true
    printErrors: false
    onLoaded: root.loadLacunaSettings(text())
    onFileChanged: reload()
    onLoadFailed: root.lacunaSettings = ({})
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
      previewProc.command = [previewScript, "--config-json", root.youtubeConfigJson, root.previewRequestUrl]
      previewProc.running = true
    }
  }

  Timer {
    id: trackInfoStartTimer
    interval: 1
    repeat: false
    onTriggered: {
      if (!root.resolvingTrackInfo || root.trackInfoRequestUrl === "") return
      if (trackInfoProc.running) {
        trackInfoProc.running = false
        restart()
        return
      }
      trackInfoProc.requestUrl = root.trackInfoRequestUrl
      trackInfoProc.output = ""
      trackInfoProc.command = [infoScript, "--config-json", root.youtubeConfigJson, root.trackInfoRequestUrl]
      trackInfoProc.running = true
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
      backgroundProc.command = [backgroundScript, "--config-json", root.youtubeConfigJson, root.backgroundRequestUrl]
      backgroundProc.running = true
    }
  }

  Timer {
    interval: root.backgroundVideoEnabled ? 1000 : 2500
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
      if (root.pendingDefaultSuggestions && (root.ytdlpAvailable || root.jellyfinConfigured)) root.loadDefaultSuggestions()
    }
  }

  Process {
    id: searchProc
    property string output: ""
    property var pendingCommand: []
    property int pendingRevision: -1
    property int requestRevision: -1

    stdout: SplitParser {
      onRead: function(data) { searchProc.output += data }
    }

    onExited: function(exitCode) {
      if (requestRevision !== root.searchRevision) return
      if (root.providerSearchActive) {
        var youtubeRows = []
        var youtubeError = ""
        try {
          var providerPayload = JSON.parse(searchProc.output || "{}")
          youtubeRows = Array.isArray(providerPayload.results) ? providerPayload.results : []
          youtubeError = providerPayload.error || ""
        } catch (e) {
          youtubeError = "Search failed"
        }
        root.completeProviderSearch("youtube", youtubeRows, youtubeError, requestRevision)
        return
      }
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
    id: jellyfinSearchProc
    property string output: ""
    property var pendingCommand: []
    property int pendingRevision: -1
    property int requestRevision: -1

    stdout: SplitParser {
      onRead: function(data) { jellyfinSearchProc.output += data }
    }

    onExited: function(exitCode) {
      if (requestRevision !== root.searchRevision) return
      var rows = []
      var error = ""
      try {
        var payload = JSON.parse(jellyfinSearchProc.output || "{}")
        rows = Array.isArray(payload.results) ? payload.results : []
        error = payload.error || ""
      } catch (e) {
        error = "Jellyfin search failed"
      }
      root.completeProviderSearch("jellyfin", rows, error, requestRevision)
    }
  }

  Process {
    id: authProc
  }

  Process {
    id: jellyfinStreamProc
    property string output: ""
    property string requestUrl: ""
    property real requestStartAt: 0

    stdout: SplitParser {
      onRead: function(data) { jellyfinStreamProc.output += data }
    }

    onExited: function(exitCode) {
      if (requestUrl !== root.trackUrl(root.currentTrack)) return
      root.commandRunning = false
      if (exitCode !== 0) {
        root.resolvingPreview = false
        root.resolvingBackground = false
        root.backgroundResolveFailed = root.backgroundVideoEnabled
        root.errorText = "Jellyfin stream unavailable"
        root.status = "error"
        return
      }
      try {
        var payload = JSON.parse(output || "{}")
        var streamUrl = String(payload.url || "")
        if (streamUrl === "") throw new Error(payload.error || "empty stream URL")
        root.applyJellyfinStream(root.currentTrack, streamUrl)
        root.startMpvResolved(root.currentTrack, streamUrl, requestStartAt)
      } catch (e) {
        root.resolvingPreview = false
        root.resolvingBackground = false
        root.backgroundResolveFailed = root.backgroundVideoEnabled
        root.errorText = "Jellyfin stream unavailable"
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
      if (exitCode !== 0) {
        if (root.resolvingBackground && root.backgroundRequestUrl === previewProc.requestUrl) {
          root.resolvingBackground = false
          root.backgroundResolveFailed = true
        }
        return
      }
      try {
        var payload = JSON.parse(previewProc.output || "{}")
        root.previewStreamUrl = payload.url || ""
        root.rememberStreamUrl(previewProc.requestUrl, root.previewStreamUrl)
        if (root.resolvingBackground && root.backgroundRequestUrl === previewProc.requestUrl && root.previewStreamUrl !== "") {
          root.backgroundStreamUrl = root.previewStreamUrl
          root.backgroundResolveFailed = false
          root.resolvingBackground = false
        }
      } catch (e) {
        root.previewStreamUrl = ""
        if (root.resolvingBackground && root.backgroundRequestUrl === previewProc.requestUrl) {
          root.resolvingBackground = false
          root.backgroundResolveFailed = true
        }
      }
    }
  }

  Process {
    id: trackInfoProc
    property string output: ""
    property string requestUrl: ""

    stdout: SplitParser {
      onRead: function(data) { trackInfoProc.output += data }
    }

    onExited: function(exitCode) {
      if (trackInfoProc.requestUrl !== root.trackInfoRequestUrl) return
      root.resolvingTrackInfo = false
      if (trackInfoProc.requestUrl !== root.trackUrl(root.currentTrack)) return
      if (exitCode !== 0) return
      try {
        var payload = JSON.parse(trackInfoProc.output || "{}")
        var resolved = root.normalizeTrack(payload.track)
        if (resolved && root.trackUrl(resolved) === root.trackUrl(root.currentTrack)) {
          root.currentTrack = resolved
          root.scheduleStateSave()
        }
        if (payload.error && String(payload.error) !== "") root.errorText = String(payload.error)
      } catch (e) {
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
      if (exitCode !== 0) {
        root.backgroundStreamUrl = ""
        root.backgroundResolveFailed = true
        try {
          var failedPayload = JSON.parse(backgroundProc.output || "{}")
          if (failedPayload.error && String(failedPayload.error) !== "") root.errorText = String(failedPayload.error)
        } catch (e) {
          root.errorText = "Background video stream unavailable"
        }
        return
      }
      try {
        var payload = JSON.parse(backgroundProc.output || "{}")
        root.backgroundStreamUrl = payload.url || ""
        root.backgroundResolveFailed = root.backgroundStreamUrl === ""
        root.rememberStreamUrl(backgroundProc.requestUrl, root.backgroundStreamUrl)
        if (root.previewRequestUrl === backgroundProc.requestUrl && root.previewStreamUrl === "") root.previewStreamUrl = root.backgroundStreamUrl
      } catch (e) {
        root.backgroundStreamUrl = ""
        root.backgroundResolveFailed = true
      }
    }
  }

  Process {
    id: backgroundPrefetchProc
    property string output: ""
    property string requestUrl: ""

    stdout: SplitParser {
      onRead: function(data) { backgroundPrefetchProc.output += data }
    }

    onExited: function(exitCode) {
      if (exitCode !== 0) return
      try {
        var payload = JSON.parse(backgroundPrefetchProc.output || "{}")
        root.rememberStreamUrl(backgroundPrefetchProc.requestUrl, payload.url || "")
      } catch (e) {
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
    id: volumeProc
  }

  Process {
    id: positionProc
    property string output: ""
    property int sessionRevision: -1

    stdout: SplitParser {
      onRead: function(data) { positionProc.output += data }
    }

    onExited: function(exitCode) {
      if (positionProc.sessionRevision !== root.playbackSessionRevision) return

      var payload = null
      try {
        payload = JSON.parse(positionProc.output || "{}")
      } catch (e) {
        payload = null
      }
      if (!payload || typeof payload !== "object") {
        root.notePlaybackProbeFailure()
        return
      }

      if (payload.ok === true) {
        root.playbackProbeFailures = 0
        var duration = Number(payload.duration)
        if (isFinite(duration) && duration > 0) root.playbackDuration = duration

        // idle-active alone can be ambiguous while a file is still loading, so
        // it only counts as an ended track once a duration was ever observed.
        if (payload.eofReached === true || (payload.idleActive === true && root.playbackDuration > 0)) {
          root.notePlaybackEnded()
          return
        }

        var value = Number(payload.timePos)
        if (isFinite(value) && value >= 0) {
          root.playbackPosition = value
          root.prefetchNextBackground()
          if (root.pendingBackgroundEnable) {
            root.pendingBackgroundEnable = false
            backgroundEnableFallback.stop()
            root.backgroundVideoEnabled = true
          }
        } else if (root.pendingBackgroundEnable) {
          backgroundEnableFallback.restart()
        }
        return
      }

      // mpv did not answer. A dead player that had already reached the end of
      // a known duration is a finished track (covers mpv builds or configs
      // that exit at EOF despite --keep-open); everything else stays on the
      // probe-failure path so genuine stream failures still surface.
      if (payload.running !== true && root.playbackLooksFinished()) {
        root.notePlaybackEnded()
        return
      }
      root.notePlaybackProbeFailure()
    }
  }

  Process {
    id: favoritesRefreshProc
    property string output: ""

    stdout: SplitParser {
      onRead: function(data) { favoritesRefreshProc.output += data }
    }

    onExited: function(exitCode) {
      root.refreshingFavorites = false
      if (exitCode !== 0) {
        root.errorText = "Favorite metadata refresh failed"
        root.status = "error"
        return
      }
      try {
        var payload = JSON.parse(favoritesRefreshProc.output || "{}")
        if (payload.error && String(payload.error) !== "") root.errorText = String(payload.error)
        if (Number(payload.changed || 0) > 0) {
          root.acceptNextStateReload = true
          stateFileView.reload()
        }
      } catch (e) {
        root.errorText = "Favorite metadata refresh failed"
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

  Timer {
    id: statePermissionsTimer
    interval: 150
    repeat: false
    onTriggered: {
      root.statePermissionChangePending = true
      statePermissionsProc.running = false
      statePermissionsProc.command = ["chmod", "600", root.stateFile]
      statePermissionsProc.running = true
      statePermissionsResetTimer.restart()
    }
  }

  Timer {
    id: statePermissionsResetTimer
    interval: 500
    repeat: false
    onTriggered: root.statePermissionChangePending = false
  }

  Process {
    id: statePermissionsProc
  }

  FileView {
    id: stateFileView

    path: root.stateFile
    watchChanges: true
    atomicWrites: true
    printErrors: false
    onLoaded: {
      var raw = text()
      if (root.lastWrittenStatePayload !== "" && raw === root.lastWrittenStatePayload) {
        root.lastWrittenStatePayload = ""
        return
      }
      if (root.stateLoaded && !root.acceptNextStateReload) return
      root.acceptNextStateReload = false
      root.applyLoadedState(raw)
    }
    onFileChanged: {
      if (root.statePermissionChangePending) {
        root.statePermissionChangePending = false
        return
      }
      if (root.suppressStateReloads > 0) {
        root.suppressStateReloads -= 1
      } else {
        root.acceptNextStateReload = true
        reload()
      }
    }
    onLoadFailed: {
      legacyStateFileView.reload()
    }
  }

  FileView {
    id: legacyStateFileView

    path: root.legacyStateFile
    watchChanges: false
    printErrors: false
    onLoaded: {
      if (root.stateLoaded) return
      root.applyLoadedState(text())
      root.saveStateNow()
    }
    onLoadFailed: {
      if (root.stateLoaded) return
      root.applyLoadedState("{}")
      root.saveStateNow()
    }
  }

  IpcHandler {
    id: mediaPlayerIpc

    target: "lacuna-media-player"

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
        playbackDuration: root.playbackDuration,
        playbackEndHandled: root.playbackEndHandled,
        previewReady: root.previewStreamUrl !== "",
        previewResolving: root.resolvingPreview,
        trackInfoResolving: root.resolvingTrackInfo,
        currentTrackUrl: root.currentTrackUrl,
        backgroundReady: root.backgroundStreamUrl !== "",
        backgroundResolving: root.resolvingBackground,
        backgroundResolveFailed: root.backgroundResolveFailed,
        previewTelemetry: root.previewTelemetry,
        backgroundOwnsAudio: root.backgroundOwnsAudio,
        backgroundPlaybackSocket: root.backgroundPlaybackSocket,
        backgroundRequestRevision: root.backgroundRequestRevision,
        queueLength: root.queue.length,
        favoritesLength: root.favoritesLength,
        refreshingFavorites: root.refreshingFavorites,
        currentFavorite: root.currentFavorite,
        repeatMode: root.repeatMode,
        searchFilter: root.searchFilter,
        youtubeLoginEnabled: root.youtubeLoginEnabled
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

    function refreshBackgroundStream(): string {
      root.refreshBackgroundStream()
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

    function playFavoriteIndex(index: string): string {
      root.playFavorite(Math.max(0, Math.round(Number(index) || 0)))
      return status()
    }

    function playUrl(url: string): string {
      root.playUrl(url)
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

    function refreshFavoriteMetadata(): string {
      root.refreshFavoriteMetadata()
      return status()
    }

    function cycleRepeatMode(): string {
      root.cycleRepeatMode()
      return status()
    }

    function openYoutubeLogin(): string {
      root.openYoutubeLogin()
      return status()
    }

    function openYoutubeMusicLogin(): string {
      root.openYoutubeMusicLogin()
      return status()
    }
  }

  IpcHandler {
    target: "lacuna-youtube-music"

    function status(): string { return mediaPlayerIpc.status() }
    function setBackgroundVideo(enabled: string): string { return mediaPlayerIpc.setBackgroundVideo(enabled) }
    function toggleBackgroundVideo(): string { return mediaPlayerIpc.toggleBackgroundVideo() }
    function refreshBackgroundStream(): string { return mediaPlayerIpc.refreshBackgroundStream() }
    function playPause(): string { return mediaPlayerIpc.playPause() }
    function playNext(): string { return mediaPlayerIpc.playNext() }
    function playFavoriteIndex(index: string): string { return mediaPlayerIpc.playFavoriteIndex(index) }
    function playUrl(url: string): string { return mediaPlayerIpc.playUrl(url) }
    function toggleFavoriteCurrent(): string { return mediaPlayerIpc.toggleFavoriteCurrent() }
    function clearFavorites(): string { return mediaPlayerIpc.clearFavorites() }
    function refreshFavoriteMetadata(): string { return mediaPlayerIpc.refreshFavoriteMetadata() }
    function cycleRepeatMode(): string { return mediaPlayerIpc.cycleRepeatMode() }
    function openYoutubeLogin(): string { return mediaPlayerIpc.openYoutubeLogin() }
    function openYoutubeMusicLogin(): string { return mediaPlayerIpc.openYoutubeMusicLogin() }
  }
}
