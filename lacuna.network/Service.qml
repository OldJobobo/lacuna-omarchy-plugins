import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import "NetworkModel.js" as Model

Item {
  id: root

  property string omarchyPath: ""
  property var shell: null
  property var manifest: null
  property var settings: ({})

  property string kind: "disconnected"
  property string label: ""
  property int signalStrength: -1
  property string frequency: ""
  property var wifiNetworks: []
  property bool scanning: false
  property bool wifiStationAvailable: false
  property string actionSsid: ""
  property string actionKind: ""
  property string failureSsid: ""
  property string failureReason: ""
  property string lastError: ""

  readonly property bool networkManagerAvailable: Networking.backend === NetworkBackendType.NetworkManager
  readonly property bool wifiEnabled: Networking.wifiEnabled
  readonly property var networkDevices: Networking.devices ? Networking.devices.values : []
  readonly property var wifiDevice: findDevice(DeviceType.Wifi)
  readonly property var wifiNetworkObjects: wifiDevice && wifiDevice.networks ? wifiDevice.networks.values : []
  readonly property var connectedWifiNetwork: findConnectedWifiNetwork()
  readonly property bool connected: kind === "wifi" || kind === "ethernet"
  readonly property bool busy: actionKind !== ""
  readonly property string icon: Model.connectionIcon(kind, signalStrength)
  readonly property string displayTitle: kind === "wifi" ? "Wi-Fi" : kind === "ethernet" ? "Ethernet" : "Network"
  readonly property string displayLabel: label || (connected ? displayTitle : "Disconnected")
  readonly property string displayFrequency: Model.frequencyLabel(frequency)

  function findDevice(type) {
    var devices = networkDevices || []
    for (var i = 0; i < devices.length; i++) {
      if (devices[i] && devices[i].type === type) return devices[i]
    }
    return null
  }

  function findConnectedWifiNetwork() {
    var networks = wifiNetworkObjects || []
    for (var i = 0; i < networks.length; i++) {
      if (networks[i] && networks[i].connected) return networks[i]
    }
    return null
  }

  function updateNetwork(raw) {
    var parsed = Model.parseNetworkStatus(raw)
    kind = parsed.kind
    label = parsed.label
    signalStrength = parsed.signalStrength
    frequency = parsed.frequency
  }

  function refresh(scanWifi) {
    if (!statusProc.running) statusProc.running = true
    if (scanWifi === true && wifiDevice) {
      scanning = true
      wifiDevice.scannerEnabled = false
      scanRestart.restart()
    } else if (wifiDevice) {
      wifiDevice.scannerEnabled = true
    }
    syncWifiNetworks()
  }

  function syncWifiNetworks() {
    var nets = []
    var networks = wifiNetworkObjects || []
    for (var i = 0; i < networks.length; i++) {
      var network = networks[i]
      if (!network) continue
      checkActionCompletion(network)
      var row = Model.wifiRow(network)
      if (row) nets.push(row)
    }
    wifiNetworks = Model.sortWifiRows(nets)
    wifiStationAvailable = !!wifiDevice
    if (!scanDone.running) scanning = false
  }

  function networkForSsid(ssid) {
    var networks = wifiNetworkObjects || []
    for (var i = 0; i < networks.length; i++) {
      if (networks[i] && networks[i].name === ssid) return networks[i]
    }
    return null
  }

  function isProtected(security) {
    return Model.isProtected(security, WifiSecurityType.Open)
  }

  function canForgetNetwork(row) {
    return !!(row && row.known && !row.connected)
  }

  function runNetworkAction(kindName, network, callback) {
    if (busy || !network) return false
    actionSsid = network.name || ""
    actionKind = kindName
    failureSsid = ""
    failureReason = ""
    lastError = ""
    callback(network)
    actionTimeout.restart()
    syncWifiNetworks()
    return true
  }

  function clearNetworkAction() {
    actionTimeout.stop()
    failureSsid = ""
    failureReason = ""
    actionSsid = ""
    actionKind = ""
    refresh(false)
  }

  function failNetworkAction(network, reason) {
    if (!network || actionKind === "" || actionSsid !== (network.name || "")) return
    actionTimeout.stop()
    failureSsid = actionSsid
    failureReason = Model.networkFailureReason(reason, {
      NoSecrets: ConnectionFailReason.NoSecrets,
      WifiAuthTimeout: ConnectionFailReason.WifiAuthTimeout,
      WifiNetworkLost: ConnectionFailReason.WifiNetworkLost,
      WifiClientDisconnected: ConnectionFailReason.WifiClientDisconnected,
      WifiClientFailed: ConnectionFailReason.WifiClientFailed
    })
    lastError = failureReason
    actionSsid = ""
    actionKind = ""
    refresh(false)
  }

  function checkActionCompletion(network) {
    if (!network || actionKind === "" || actionSsid !== (network.name || "")) return
    if (actionKind === "connect" && network.connected) clearNetworkAction()
    else if (actionKind === "disconnect" && !network.connected && !network.stateChanging) clearNetworkAction()
    else if (actionKind === "forget" && !network.known && !network.stateChanging) clearNetworkAction()
  }

  function connectKnown(ssid) {
    return runNetworkAction("connect", networkForSsid(ssid), function(network) { network.connect() })
  }

  function connectWithPassphrase(ssid, passphrase) {
    return runNetworkAction("connect", networkForSsid(ssid), function(network) { network.connectWithPsk(passphrase) })
  }

  function disconnect(network) {
    return runNetworkAction("disconnect", network || connectedWifiNetwork, function(net) { net.disconnect() })
  }

  function forget(row) {
    return runNetworkAction("forget", row && row.network ? row.network : null, function(network) { network.forget() })
  }

  function toggleWifi() {
    Networking.wifiEnabled = !Networking.wifiEnabled
    refresh(true)
  }

  function tooltip() {
    var body = displayLabel
    if (kind === "wifi" && signalStrength >= 0) body += "<br/>Signal: " + signalStrength + "%"
    if (displayFrequency) body += "<br/>" + displayFrequency
    if (!networkManagerAvailable) body += "<br/>NetworkManager backend unavailable"
    return displayTitle + "<br/>" + body
  }

  function statusJson() {
    return JSON.stringify({
      kind: kind,
      label: label,
      signalStrength: signalStrength,
      frequency: frequency,
      connected: connected,
      wifiEnabled: wifiEnabled,
      networkManagerAvailable: networkManagerAvailable,
      wifiStationAvailable: wifiStationAvailable,
      wifiNetworks: wifiNetworks.length,
      scanning: scanning,
      busy: busy,
      actionSsid: actionSsid,
      actionKind: actionKind,
      failureSsid: failureSsid,
      failureReason: failureReason
    })
  }

  Component.onCompleted: refresh(true)
  onWifiDeviceChanged: {
    if (wifiDevice) wifiDevice.scannerEnabled = true
    syncWifiNetworks()
  }
  onWifiNetworkObjectsChanged: syncWifiNetworks()

  Timer {
    interval: 5000
    running: true
    repeat: true
    onTriggered: root.refresh(false)
  }

  Timer {
    id: scanRestart
    interval: 100
    repeat: false
    onTriggered: {
      if (root.wifiDevice) root.wifiDevice.scannerEnabled = true
      scanDone.restart()
    }
  }

  Timer {
    id: scanDone
    interval: 1500
    repeat: false
    onTriggered: root.syncWifiNetworks()
  }

  Timer {
    id: actionTimeout
    interval: 12000
    repeat: false
    onTriggered: {
      root.lastError = "Network action timed out"
      root.actionSsid = ""
      root.actionKind = ""
      root.refresh(false)
    }
  }

  Process {
    id: statusProc
    command: ["omarchy", "network", "status"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.updateNetwork(text)
    }
  }

  IpcHandler {
    target: "lacuna-network"

    function status(): string {
      return root.statusJson()
    }

    function refresh(): string {
      root.refresh(true)
      return root.statusJson()
    }

    function toggleWifi(): string {
      root.toggleWifi()
      return root.statusJson()
    }
  }
}
