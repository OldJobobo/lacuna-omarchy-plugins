function clamp(value, minimum, maximum) {
  var n = Number(value)
  if (!isFinite(n)) n = minimum
  return Math.max(minimum, Math.min(maximum, n))
}

function percent(volume) {
  return Math.round(clamp(volume, 0, 1.5) * 100)
}

function outputIcon(hasSink, muted, volume) {
  if (!hasSink || muted || volume <= 0) return ""
  if (volume >= 0.67) return ""
  if (volume >= 0.34) return ""
  return ""
}

function inputIcon(hasSource, muted) {
  if (!hasSource) return "󰍭"
  return muted ? "󰍭" : "󰍬"
}

function outputMood(volume, muted) {
  if (muted) return "Muted"
  var p = percent(volume)
  if (p === 0) return "Silenced"
  if (p >= 100) return "Overdrive"
  if (p >= 75) return "Loud"
  if (p >= 45) return "Present"
  if (p >= 20) return "Low"
  return "Whisper"
}

function nodeProps(node) {
  return node && node.ready && node.properties ? node.properties : {}
}

function friendlyLabel(text) {
  var label = String(text || "").trim()
  label = label.replace(/^sof-soundwire\s+/i, "")
  label = label.replace(/^built-?in audio\s+/i, "")
  label = label.replace(/\s+Output$/i, "")
  label = label.replace(/\s+Input$/i, "")
  label = label.replace(/\bMicrophones\b/g, "Microphone")
  return label
}

function nodeLabel(node) {
  if (!node) return "Unknown"
  var p = nodeProps(node)
  return friendlyLabel(node.nickname || node.nick || p["node.nick"] || p["device.profile.description"] || node.description || p["node.description"] || node.name || "Unknown")
}

function isPlaybackStream(node) {
  if (!node || !node.isStream) return false
  if (node.isSink === true) return true
  var mediaClass = String(node.type || "")
  return mediaClass.indexOf("Stream/Output/Audio") !== -1
    || mediaClass.indexOf("AudioOutStream") !== -1
    || mediaClass.indexOf("Output") !== -1
}

function isAudioSource(node) {
  if (!node) return false
  if (node.audio) return true
  var mediaClass = String(node.type || "")
  return mediaClass.indexOf("Audio/Source") !== -1
    || mediaClass.indexOf("AudioSource") !== -1
    || mediaClass.indexOf("Source") !== -1
}

function streamLabel(node) {
  if (!node) return "Stream"
  var p = nodeProps(node)
  return friendlyLabel(p["application.name"] || node.description || p["media.name"] || p["node.name"] || node.name || "Stream")
}

if (typeof module !== "undefined") {
  module.exports = {
    clamp: clamp,
    percent: percent,
    outputIcon: outputIcon,
    inputIcon: inputIcon,
    outputMood: outputMood,
    nodeProps: nodeProps,
    friendlyLabel: friendlyLabel,
    nodeLabel: nodeLabel,
    isPlaybackStream: isPlaybackStream,
    isAudioSource: isAudioSource,
    streamLabel: streamLabel
  }
}
