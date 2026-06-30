import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "AudioModel.js" as Model

Item {
  id: root

  property string omarchyPath: ""
  property var shell: null
  property var manifest: null
  property var settings: ({})

  readonly property var sink: Pipewire.defaultAudioSink
  readonly property var source: Pipewire.defaultAudioSource
  readonly property var nodes: Pipewire.nodes ? Pipewire.nodes.values : []
  readonly property bool hasSink: !!sink && !!sink.audio
  readonly property bool hasSource: !!source && !!source.audio
  readonly property bool outputMuted: hasSink ? sink.audio.muted : true
  readonly property bool inputMuted: hasSource ? source.audio.muted : true
  readonly property real outputVolume: hasSink ? sink.audio.volume : 0
  readonly property real inputVolume: hasSource ? source.audio.volume : 0
  readonly property int outputPercent: Model.percent(outputVolume)
  readonly property int inputPercent: Model.percent(inputVolume)
  readonly property string outputIcon: Model.outputIcon(hasSink, outputMuted, outputVolume)
  readonly property string inputIcon: Model.inputIcon(hasSource, inputMuted)
  readonly property string outputLabel: hasSink ? Model.nodeLabel(sink) : "No output"
  readonly property string inputLabel: hasSource ? Model.nodeLabel(source) : "No input"
  readonly property string outputMood: Model.outputMood(outputVolume, outputMuted)

  readonly property var sinks: {
    var list = []
    for (var i = 0; i < nodes.length; i++) {
      var n = nodes[i]
      if (n && n.isSink && !n.isStream) list.push(n)
    }
    if (sink && list.indexOf(sink) < 0) list.unshift(sink)
    return list
  }

  readonly property var sources: {
    var list = []
    for (var i = 0; i < nodes.length; i++) {
      var n = nodes[i]
      if (n && !n.isSink && !n.isStream && Model.isAudioSource(n)) {
        var name = n.name || ""
        if (name !== "quickshell") list.push(n)
      }
    }
    if (source && list.indexOf(source) < 0) list.unshift(source)
    return list
  }

  readonly property var streams: {
    var list = []
    for (var i = 0; i < nodes.length; i++) {
      var n = nodes[i]
      if (n && n.audio && Model.isPlaybackStream(n)) list.push(n)
    }
    return list
  }

  PwObjectTracker { objects: root.sinks }
  PwObjectTracker { objects: root.sources }
  PwObjectTracker { objects: root.streams }

  function setOutputVolume(value) {
    if (hasSink) sink.audio.volume = Model.clamp(value, 0, 1.5)
  }

  function adjustOutputVolume(delta) {
    setOutputVolume(outputVolume + Number(delta || 0))
  }

  function setInputVolume(value) {
    if (hasSource) source.audio.volume = Model.clamp(value, 0, 1.5)
  }

  function toggleOutputMute() {
    if (hasSink) sink.audio.muted = !sink.audio.muted
  }

  function toggleInputMute() {
    if (hasSource) source.audio.muted = !source.audio.muted
  }

  function setDefaultSink(node) {
    if (node) Pipewire.preferredDefaultAudioSink = node
  }

  function setDefaultSource(node) {
    if (node) Pipewire.preferredDefaultAudioSource = node
  }

  function nodeLabel(node) {
    return Model.nodeLabel(node)
  }

  function streamLabel(node) {
    return Model.streamLabel(node)
  }

  function setStreamVolume(node, value) {
    if (node && node.audio) node.audio.volume = Model.clamp(value, 0, 1.5)
  }

  function toggleStreamMute(node) {
    if (node && node.audio) node.audio.muted = !node.audio.muted
  }

  function tooltip() {
    if (!hasSink) return "No audio sink"
    return (outputMuted ? "Muted" : "Volume " + outputPercent + "%") + "<br/>" + outputLabel
  }

  function statusJson() {
    return JSON.stringify({
      hasSink: hasSink,
      hasSource: hasSource,
      outputMuted: outputMuted,
      inputMuted: inputMuted,
      outputPercent: outputPercent,
      inputPercent: inputPercent,
      outputLabel: outputLabel,
      inputLabel: inputLabel,
      sinks: sinks.length,
      sources: sources.length,
      streams: streams.length
    })
  }

  IpcHandler {
    target: "lacuna-audio"

    function status(): string {
      return root.statusJson()
    }

    function toggleMute(): string {
      root.toggleOutputMute()
      return root.statusJson()
    }
  }
}
