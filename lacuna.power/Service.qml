import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import "PowerModel.js" as Model

Item {
  id: root

  property string omarchyPath: ""
  property var shell: null
  property var manifest: null
  property var settings: ({})
  property var batteryInfo: ({})
  property var systemInfo: ({})
  property var profiles: []
  property string activeProfile: ""
  property int profileIndex: 0

  readonly property var device: UPower.displayDevice
  readonly property bool hasBattery: !!(device && device.isPresent)
  readonly property bool onBattery: UPower.onBattery
  readonly property var states: ({
    Charging: UPowerDeviceState.Charging,
    Discharging: UPowerDeviceState.Discharging,
    FullyCharged: UPowerDeviceState.FullyCharged,
    PendingCharge: UPowerDeviceState.PendingCharge
  })
  readonly property real fraction: Model.batteryFraction(device)
  readonly property int percent: Math.round(fraction * 100)
  readonly property bool chargeThresholdActive: Model.chargeThresholdActive(device, onBattery, states)
  readonly property bool charging: hasBattery && device.state === UPowerDeviceState.Charging && !chargeThresholdActive
  readonly property bool discharging: hasBattery && (onBattery || device.state === UPowerDeviceState.Discharging)
  readonly property bool full: hasBattery && device.state === UPowerDeviceState.FullyCharged && !chargeThresholdActive
  readonly property bool low: discharging && fraction > 0 && fraction <= 0.2
  readonly property string icon: Model.batteryIcon(device, onBattery, states)
  readonly property string modeLabel: Model.modeLabel(device, onBattery, states)
  readonly property string activeProfileIcon: Model.profileIcon(activeProfile)
  readonly property string activeProfileLabel: Model.profileLabel(activeProfile)

  function refresh() {
    if (!batteryProc.running) batteryProc.running = true
    if (!profilesProc.running) profilesProc.running = true
    if (!systemProc.running) systemProc.running = true
  }

  function updateKeyValue(raw, targetName) {
    var next = Model.parseKeyValue(raw)
    if (Object.keys(next).length === 0) return
    if (targetName === "battery") batteryInfo = next
    else systemInfo = next
  }

  function updateProfiles(raw) {
    var parsed = Model.parseProfiles(raw, profileIndex)
    if (parsed.profiles.length === 0) return
    profiles = parsed.profiles
    activeProfile = parsed.activeProfile
    profileIndex = parsed.profileIndex
  }

  function setProfile(profile) {
    if (!profile || actionProc.running) return
    actionProc.command = ["powerprofilesctl", "set", profile]
    actionProc.running = true
  }

  function profileIcon(name) {
    return Model.profileIcon(name)
  }

  function profileLabel(name) {
    return Model.profileLabel(name)
  }

  function tooltip() {
    if (!hasBattery) return "Power<br/>AC power"
    return "Power<br/>" + modeLabel + "<br/>" + percent + "%"
  }

  function statusJson() {
    return JSON.stringify({
      hasBattery: hasBattery,
      onBattery: onBattery,
      charging: charging,
      discharging: discharging,
      full: full,
      low: low,
      percent: percent,
      modeLabel: modeLabel,
      profiles: profiles.length,
      activeProfile: activeProfile
    })
  }

  Component.onCompleted: refresh()

  Timer {
    interval: 5000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Process {
    id: batteryProc
    command: [root.omarchyPath ? root.omarchyPath + "/bin/omarchy-battery-status" : "omarchy-battery-status", "--shell"]
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: root.updateKeyValue(text, "battery") }
  }

  Process {
    id: profilesProc
    command: [root.omarchyPath ? root.omarchyPath + "/bin/omarchy-powerprofiles-list" : "omarchy-powerprofiles-list", "--active-state"]
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: root.updateProfiles(text) }
  }

  Process {
    id: systemProc
    command: [root.omarchyPath ? root.omarchyPath + "/bin/omarchy-system-stats" : "omarchy-system-stats"]
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: root.updateKeyValue(text, "system") }
  }

  Process {
    id: actionProc
    onExited: root.refresh()
  }

  IpcHandler {
    target: "lacuna-power"

    function status(): string {
      return root.statusJson()
    }

    function refresh(): string {
      root.refresh()
      return root.statusJson()
    }
  }
}
