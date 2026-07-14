import QtQuick
import Quickshell
import Quickshell.Io
import "WeatherModel.js" as Model

Item {
  id: root

  property var settings: ({})
  property bool autoRefresh: true
  property var report: null
  property var dailyReport: null
  property var forecastDays: []
  property bool loading: false
  property bool stale: false
  property string errorText: ""
  property date lastUpdated: new Date(0)
  property string activeWeatherKey: ""
  property string activeDailyKey: ""
  property var resolvedLocation: null
  property bool refreshPending: false
  property bool initialized: false
  property double lastRequestMs: 0

  readonly property string locationOverride: Model.normalizeLocation(setting("location", ""))
  readonly property string unitSetting: Model.normalizedUnit(setting("unit", "auto"))
  readonly property int intervalMs: Math.max(60000, Number(setting("interval", 900000)) || 900000)
  readonly property string requestKey: locationOverride + "|" + unitSetting
  readonly property bool hasData: !!report
  readonly property var current: Model.currentData(report, unitSetting, Qt.locale().name, locationOverride)
  readonly property bool useImperial: current.useImperial === true
  readonly property string icon: current.icon || "󰖐"
  readonly property string barLabel: current.barLabel || ""
  readonly property string statusLabel: loading && !hasData ? "FETCHING" : stale ? "STALE" : hasData ? "LIVE" : "OFFLINE"
  readonly property bool requestRunning: locationProc.running || openMeteoProc.running || weatherProc.running

  signal refreshFinished(bool success)

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function refresh(force) {
    var now = Date.now()
    if (!force && hasData && now - lastRequestMs < 60000) return
    if (requestRunning) {
      refreshPending = true
      return
    }

    lastRequestMs = now
    activeWeatherKey = requestKey
    loading = !hasData
    errorText = ""
    resolvedLocation = null
    locationProc.command = ["curl", "-fsS", "--max-time", "5", Model.buildLocationUrl(locationOverride)]
    locationProc.running = true
  }

  function startWttrFallback() {
    weatherProc.command = ["curl", "-fsS", "--max-time", "5", Model.buildWttrUrl(locationOverride)]
    weatherProc.running = true
  }

  function finishLocationRequest(raw) {
    if (activeWeatherKey !== requestKey) {
      loading = false
      refreshPending = false
      Qt.callLater(function() { root.refresh(true) })
      return
    }
    resolvedLocation = Model.parseLocation(raw, locationOverride)
    var weatherUrl = Model.buildOpenMeteoWeatherUrl(resolvedLocation)
    if (weatherUrl === "") {
      startWttrFallback()
      return
    }
    openMeteoProc.command = ["curl", "-fsS", "--max-time", "5", weatherUrl]
    openMeteoProc.running = true
  }

  function finishOpenMeteoRequest(raw) {
    if (activeWeatherKey !== requestKey) {
      loading = false
      refreshPending = false
      Qt.callLater(function() { root.refresh(true) })
      return
    }
    try {
      var parsed = JSON.parse(String(raw || ""))
      var normalized = Model.reportFromOpenMeteo(parsed, resolvedLocation)
      if (!normalized || !parsed.daily) {
        startWttrFallback()
        return
      }
      report = normalized
      dailyReport = parsed
      forecastDays = Model.buildForecastDays(report, dailyReport, Qt.formatDate(new Date(), "yyyy-MM-dd"))
      lastUpdated = new Date()
      stale = false
      loading = false
      errorText = ""
      refreshFinished(true)
      runPendingRefresh()
    } catch (error) {
      startWttrFallback()
    }
  }

  function finishWeatherRequest(raw) {
    var responseKey = activeWeatherKey
    var parsed = Model.parseReport(raw)
    if (responseKey !== requestKey) {
      loading = false
      refreshPending = false
      Qt.callLater(function() { root.refresh(true) })
      return
    }

    if (!parsed) {
      loading = false
      stale = hasData
      errorText = hasData ? "Update failed — showing last report" : "Forecast unavailable"
      refreshFinished(false)
      runPendingRefresh()
      return
    }

    report = parsed
    dailyReport = null
    forecastDays = Model.buildForecastDays(report, null, Qt.formatDate(new Date(), "yyyy-MM-dd"))
    lastUpdated = new Date()
    stale = false
    loading = false
    errorText = ""
    refreshFinished(true)

    var dailyUrl = Model.openMeteoUrl(parsed)
    if (dailyUrl !== "" && !dailyProc.running) {
      activeDailyKey = responseKey
      dailyProc.command = ["curl", "-fsS", "--max-time", "5", dailyUrl]
      dailyProc.running = true
    }
    runPendingRefresh()
  }

  function finishDailyRequest(raw) {
    if (activeDailyKey !== requestKey) return
    try {
      var parsed = JSON.parse(String(raw || ""))
      if (!parsed || !parsed.daily) return
      dailyReport = parsed
      forecastDays = Model.buildForecastDays(report, dailyReport, Qt.formatDate(new Date(), "yyyy-MM-dd"))
    } catch (error) {
      // The wttr forecast already remains visible as the last-good fallback.
    }
  }

  function runPendingRefresh() {
    if (!refreshPending) return
    refreshPending = false
    Qt.callLater(function() { root.refresh(true) })
  }

  function forecastDayName(day) {
    return Model.dayName(day ? day.date : "", Qt.locale())
  }

  function forecastTemperature(day, kind) {
    return Model.forecastTemperature(day, kind, useImperial)
  }

  function notificationText() {
    return Model.notificationText(current)
  }

  onLocationOverrideChanged: {
    dailyReport = null
    forecastDays = []
    if (initialized && autoRefresh) refresh(true)
  }

  Component.onCompleted: {
    initialized = true
    if (autoRefresh) refresh(true)
  }

  Timer {
    interval: root.intervalMs
    running: root.autoRefresh
    repeat: true
    onTriggered: root.refresh(false)
  }

  Process {
    id: locationProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.finishLocationRequest(text)
    }
  }

  Process {
    id: openMeteoProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.finishOpenMeteoRequest(text)
    }
  }

  Process {
    id: weatherProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.finishWeatherRequest(text)
    }
  }

  Process {
    id: dailyProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.finishDailyRequest(text)
    }
  }
}
