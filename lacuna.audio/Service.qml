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

  // Repeaters must never own transient PwNode QObjects. PipeWire can destroy a
  // node while Qt is regenerating delegates, which caused the shell crash this
  // service is designed to survive. Track live nodes privately and expose only
  // value snapshots with stable keys to UI models.
  readonly property var liveSinks: collectLiveNodes("sink")
  readonly property var liveSources: collectLiveNodes("source")
  readonly property var liveStreams: collectLiveNodes("stream")
  property var sinks: []
  property var sources: []
  property var streams: []
  property string rowSignature: ""

  PwObjectTracker { objects: root.liveSinks }
  PwObjectTracker { objects: root.liveSources }
  PwObjectTracker { objects: root.liveStreams }

  function collectLiveNodes(kind) {
    var list = []
    for (var i = 0; i < nodes.length; i++) {
      var node = nodes[i]
      if (!node) continue
      if (kind === "sink" && node.isSink && !node.isStream) list.push(node)
      else if (kind === "source" && !node.isSink && !node.isStream && Model.isAudioSource(node) && String(node.name || "") !== "quickshell") list.push(node)
      else if (kind === "stream" && node.audio && Model.isPlaybackStream(node)) list.push(node)
    }
    var preferred = kind === "sink" ? sink : kind === "source" ? source : null
    if (preferred && list.indexOf(preferred) < 0) list.unshift(preferred)
    return list
  }

  function snapshotRows(liveNodes, kind, preferred) {
    var rows = []
    for (var i = 0; i < liveNodes.length; i++) {
      var node = liveNodes[i]
      var row = Model.snapshotRow(node, kind, node === preferred)
      if (row.key === "") continue
      rows.push(row)
    }
    return rows
  }

  function refreshRows() {
    var nextSinks = snapshotRows(liveSinks, "sink", sink)
    var nextSources = snapshotRows(liveSources, "source", source)
    var nextStreams = snapshotRows(liveStreams, "stream", null)
    var signature = JSON.stringify([nextSinks, nextSources, nextStreams])
    if (signature === rowSignature) return
    rowSignature = signature
    sinks = nextSinks
    sources = nextSources
    streams = nextStreams
  }

  function scheduleRowRefresh() {
    rowRefresh.restart()
  }

  function resolveLiveNode(reference) {
    if (!reference) return null
    var key = reference.key !== undefined ? String(reference.key) : Model.nodeKey(reference)
    if (key === "") return null
    for (var i = 0; i < nodes.length; i++) {
      var node = nodes[i]
      if (node && Model.nodeKey(node) === key) return node
    }
    return null
  }

  onNodesChanged: scheduleRowRefresh()
  onSinkChanged: scheduleRowRefresh()
  onSourceChanged: scheduleRowRefresh()
  Component.onCompleted: scheduleRowRefresh()

  Timer {
    id: rowRefresh
    interval: 0
    repeat: false
    onTriggered: root.refreshRows()
  }

  Timer {
    interval: 250
    running: true
    repeat: true
    onTriggered: root.refreshRows()
  }

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

  function setDefaultSink(reference) {
    var node = resolveLiveNode(reference)
    if (node) Pipewire.preferredDefaultAudioSink = node
  }

  function setDefaultSource(reference) {
    var node = resolveLiveNode(reference)
    if (node) Pipewire.preferredDefaultAudioSource = node
  }

  function nodeLabel(reference) {
    return reference && reference.label !== undefined ? String(reference.label) : Model.nodeLabel(reference)
  }

  function streamLabel(reference) {
    return reference && reference.label !== undefined ? String(reference.label) : Model.streamLabel(reference)
  }

  function setStreamVolume(reference, value) {
    var node = resolveLiveNode(reference)
    if (node && node.audio) node.audio.volume = Model.clamp(value, 0, 1.5)
  }

  function toggleStreamMute(reference) {
    var node = resolveLiveNode(reference)
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
