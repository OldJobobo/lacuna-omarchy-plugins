import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import "BluetoothModel.js" as Model

Item {
  id: root

  property string omarchyPath: ""
  property var shell: null
  property var manifest: null
  property var settings: ({})
  property var pendingActions: ({})
  property var pendingAudioOutputDevice: null
  property int pendingAudioOutputAttempts: 0

  readonly property var adapter: Bluetooth.defaultAdapter
  readonly property var devices: Bluetooth.devices ? Bluetooth.devices.values : []
  readonly property var pipewireNodes: Pipewire.nodes ? Pipewire.nodes.values : []
  readonly property bool available: !!adapter
  readonly property bool enabled: !!adapter && adapter.enabled
  readonly property bool discovering: !!adapter && adapter.discovering
  readonly property var deviceGroups: Model.deviceLists(devices)
  readonly property var connectedDevices: deviceGroups.connected || []
  readonly property var knownDevices: deviceGroups.known || []
  readonly property var discoveredDevices: deviceGroups.discovered || []
  readonly property bool connected: connectedDevices.length > 0
  readonly property bool busy: Object.keys(pendingActions || {}).length > 0
  readonly property string icon: {
    if (!adapter) return "󰂲"
    if (!adapter.enabled) return "󰂲"
    if (connectedDevices.length > 0) return "󰂱"
    return "󰂯"
  }
  readonly property string statusText: {
    if (!adapter) return "No adapter"
    if (!adapter.enabled) return "Bluetooth off"
    if (connectedDevices.length > 0) return connectedDevices.length + " connected"
    if (knownDevices.length > 0) return knownDevices.length + " paired"
    if (adapter.discovering) return "Scanning"
    return "Ready"
  }

  function deviceLabel(device) {
    return Model.deviceLabel(device)
  }

  function pendingAction(address) {
    return Model.pendingAction(pendingActions, address)
  }

  function setPendingAction(address, action) {
    if (!address) return
    pendingActions = Model.withPendingAction(pendingActions, address, action)
    if (action) pendingTimeout.restart()
  }

  function deviceCommand(action, address) {
    var command = omarchyPath ? omarchyPath + "/bin/omarchy-bluetooth-device" : "omarchy-bluetooth-device"
    return [command, action, address]
  }

  function runDeviceAction(device, action, pending) {
    if (!device || !device.address) return false
    setPendingAction(device.address, pending)
    Quickshell.execDetached(deviceCommand(action, device.address))
    return true
  }

  function startDiscovery() {
    if (adapter && adapter.enabled) adapter.discovering = true
  }

  function stopDiscovery() {
    if (adapter) adapter.discovering = false
  }

  function toggleBluetooth() {
    if (!adapter) return
    adapter.enabled = !adapter.enabled
    if (adapter.enabled) Qt.callLater(startDiscovery)
  }

  function connectDevice(device) {
    if (!device || device.connected) return false
    if (device.paired || device.bonded || device.trusted) return runDeviceAction(device, "connect", "connecting")
    return runDeviceAction(device, "pair", "connecting")
  }

  function disconnectDevice(device) {
    if (!device || !device.address || !device.connected) return false
    setPendingAction(device.address, "disconnecting")
    if (device.disconnect) device.disconnect()
    Quickshell.execDetached(deviceCommand("disconnect", device.address))
    return true
  }

  function forgetDevice(device) {
    return runDeviceAction(device, "forget", "forgetting")
  }

  function audioSinks() {
    var sinks = []
    for (var i = 0; i < pipewireNodes.length; i++) {
      var node = pipewireNodes[i]
      if (node && node.isSink && !node.isStream) sinks.push(node)
    }
    return sinks
  }

  function bluetoothAudioSink(device) {
    var sinks = audioSinks()
    for (var i = 0; i < sinks.length; i++) {
      if (Model.bluetoothSinkMatchesDevice(sinks[i], device)) return sinks[i]
    }
    return null
  }

  function setDefaultAudioSink(sink) {
    if (!sink) return
    Pipewire.preferredDefaultAudioSink = sink
    if (omarchyPath && sink.id !== undefined && sink.name) {
      Quickshell.execDetached([
        omarchyPath + "/bin/omarchy-audio-output-set-default",
        String(sink.id),
        String(sink.name)
      ])
    }
  }

  function scheduleAudioOutputSwitch(device) {
    pendingAudioOutputDevice = {
      address: device && device.address ? device.address : "",
      name: device && device.name ? device.name : "",
      deviceName: device && device.deviceName ? device.deviceName : ""
    }
    pendingAudioOutputAttempts = 0
    audioSwitchTimer.restart()
  }

  function switchPendingAudioOutput() {
    if (!pendingAudioOutputDevice) return
    var sink = bluetoothAudioSink(pendingAudioOutputDevice)
    if (sink) {
      setDefaultAudioSink(sink)
      pendingAudioOutputDevice = null
      audioSwitchTimer.stop()
      return
    }
    pendingAudioOutputAttempts += 1
    if (pendingAudioOutputAttempts >= 8) pendingAudioOutputDevice = null
    else audioSwitchTimer.restart()
  }

  function syncPendingActions() {
    var next = Model.cloneMap(pendingActions)
    var changed = false

    for (var address in next) {
      var action = next[address]
      var found = null
      for (var i = 0; i < devices.length; i++) {
        var d = devices[i]
        if (d && d.address === address) {
          found = d
          break
        }
      }

      var finishedConnecting = action === "connecting" && found && found.connected
      if (finishedConnecting
          || (action === "disconnecting" && found && !found.connected)
          || (action === "forgetting" && (!found || (!found.paired && !found.bonded && !found.trusted)))) {
        if (finishedConnecting) scheduleAudioOutputSwitch(found)
        delete next[address]
        changed = true
      }
    }

    if (changed) pendingActions = next
  }

  function tooltip() {
    if (!adapter) return "No Bluetooth adapter"
    if (!adapter.enabled) return "Bluetooth off<br/>Right click to turn on"
    if (connectedDevices.length === 0) return "Bluetooth on<br/>No connected devices"

    var names = []
    for (var i = 0; i < connectedDevices.length; i++) {
      var label = deviceLabel(connectedDevices[i])
      if (label) names.push(label)
    }
    return "Bluetooth connected<br/>" + (names.length > 0 ? names.join("<br/>") : connectedDevices.length + " devices")
  }

  function statusJson() {
    return JSON.stringify({
      available: available,
      enabled: enabled,
      discovering: discovering,
      connected: connected,
      connectedDevices: connectedDevices.length,
      knownDevices: knownDevices.length,
      discoveredDevices: discoveredDevices.length,
      busy: busy,
      statusText: statusText
    })
  }

  PwObjectTracker { objects: root.pipewireNodes }

  onDevicesChanged: syncPendingActions()
  onAdapterChanged: if (adapter && adapter.enabled) startDiscovery()
  Component.onCompleted: if (adapter && adapter.enabled) startDiscovery()

  Timer {
    interval: 1500
    running: true
    repeat: true
    onTriggered: root.syncPendingActions()
  }

  Timer {
    id: pendingTimeout
    interval: 16000
    repeat: false
    onTriggered: root.pendingActions = ({})
  }

  Timer {
    id: audioSwitchTimer
    interval: 750
    repeat: false
    onTriggered: root.switchPendingAudioOutput()
  }

  IpcHandler {
    target: "lacuna-bluetooth"

    function status(): string {
      return root.statusJson()
    }

    function toggle(): string {
      root.toggleBluetooth()
      return root.statusJson()
    }
  }
}
