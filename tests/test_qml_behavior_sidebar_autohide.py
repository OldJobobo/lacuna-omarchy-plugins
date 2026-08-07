import unittest

from qml_harness import HAVE_SESSION, parse_behave, qml_url, require_no_qml_errors, run_quickshell


@unittest.skipUnless(HAVE_SESSION, "needs a quickshell binary and a Wayland session")
class QmlSidebarAutohideBehaviorTests(unittest.TestCase):
    def test_dwell_envelope_hide_and_explicit_rearm(self):
        qml = f"""
import Quickshell
import QtQuick

ShellRoot {{
  id: root
  property var controller: null
  property var reveals: []
  property var conceals: []
  property int step: 0

  Component.onCompleted: {{
    var component = Qt.createComponent("{qml_url('lacuna.menu/services/SidebarAutohideController.qml')}", Component.PreferSynchronous)
    if (component.status !== Component.Ready) {{
      console.log("BEHAVE_ERR " + component.errorString())
      Qt.quit()
      return
    }}
    controller = component.createObject(root, {{
      enabled: true,
      revealDelayMs: 0,
      hideDelayMs: 0
    }})
    controller.revealRequested.connect(function(name, reason) {{
      var next = root.reveals.slice()
      next.push(name + ":" + reason)
      root.reveals = next
    }})
    controller.concealRequested.connect(function(reason) {{
      var next = root.conceals.slice()
      next.push(reason)
      root.conceals = next
    }})
    controller.setEligibleScreens(["DP-1", "DP-2"])
    controller.setHotZoneHovered("DP-1", true)
    probe.restart()
  }}

  Timer {{
    id: probe
    interval: 25
    repeat: true
    onTriggered: {{
      step += 1
      if (step === 1) {{
        controller.notifyMenuProgress(1)
        controller.setSidebarHovered("DP-1", true)
        controller.setHotZoneHovered("DP-1", false)
        return
      }}
      if (step === 2) {{
        controller.setSidebarHovered("DP-1", false)
        return
      }}
      if (step === 3) {{
        controller.notifyMenuProgress(0)
        controller.setHotZoneHovered("DP-1", true)
        controller.explicitOpen("DP-1")
        controller.notifyMenuProgress(1)
        controller.explicitClose("explicit-close")
        return
      }}
      if (step === 4) {{
        controller.notifyMenuProgress(0)
        var revealsWhileBlocked = reveals.length
        controller.setHotZoneHovered("DP-1", true)
        controller.setHotZoneHovered("DP-1", false)
        controller.setHotZoneHovered("DP-1", true)
        rearmCheck.revealsWhileBlocked = revealsWhileBlocked
        return
      }}
      if (step === 5) {{
        console.log("BEHAVE " + JSON.stringify({{
          reveals: reveals,
          conceals: conceals,
          active: controller.activeScreenName,
          phase: controller.phase,
          blockedDidNotReveal: rearmCheck.revealsWhileBlocked === 2
        }}))
        Qt.quit()
      }}
    }}
  }}

  QtObject {{ id: rearmCheck; property int revealsWhileBlocked: -1 }}
}}
"""
        output = run_quickshell(qml, timeout=8)
        require_no_qml_errors(output)
        row = parse_behave(output)[-1]
        self.assertEqual("DP-1:edge-dwell", row["reveals"][0], output[-3000:])
        self.assertEqual("pointer-leave", row["conceals"][0], output[-3000:])
        self.assertEqual("DP-1:explicit-open", row["reveals"][1], output[-3000:])
        self.assertEqual("explicit-close", row["conceals"][1], output[-3000:])
        self.assertTrue(row["blockedDidNotReveal"], output[-3000:])
        self.assertEqual("DP-1:edge-dwell", row["reveals"][-1], output[-3000:])

    def test_explicit_open_still_conceals_outside_pointer_envelope(self):
        qml = f"""
import Quickshell
import QtQuick

ShellRoot {{
  id: root
  property var controller: null
  property var conceals: []

  Component.onCompleted: {{
    var component = Qt.createComponent("{qml_url('lacuna.menu/services/SidebarAutohideController.qml')}", Component.PreferSynchronous)
    if (component.status !== Component.Ready) {{
      console.log("BEHAVE_ERR " + component.errorString())
      Qt.quit()
      return
    }}
    controller = component.createObject(root, {{ enabled: true, hideDelayMs: 0 }})
    controller.concealRequested.connect(function(reason) {{ conceals.push(reason) }})
    controller.setEligibleScreens(["DP-1"])
    controller.explicitOpen("DP-1")
    controller.notifyMenuProgress(1)
    probe.restart()
  }}

  Timer {{
    id: probe
    interval: 30
    onTriggered: {{
      console.log("BEHAVE " + JSON.stringify({{
        conceals: conceals,
        explicitHeld: controller.explicitHeld,
        phase: controller.phase
      }}))
      Qt.quit()
    }}
  }}
}}
"""
        output = run_quickshell(qml, timeout=8)
        require_no_qml_errors(output)
        row = parse_behave(output)[-1]
        self.assertEqual(["pointer-leave"], row["conceals"], output[-3000:])
        self.assertFalse(row["explicitHeld"], output[-3000:])
        self.assertEqual("hiding", row["phase"], output[-3000:])

    def test_output_handoff_cannot_dismiss_semantically_held_session(self):
        qml = f"""
import Quickshell
import QtQuick

ShellRoot {{
  id: root
  property var controller: null
  property var events: []

  Component.onCompleted: {{
    var component = Qt.createComponent("{qml_url('lacuna.menu/services/SidebarAutohideController.qml')}", Component.PreferSynchronous)
    if (component.status !== Component.Ready) {{
      console.log("BEHAVE_ERR " + component.errorString())
      Qt.quit()
      return
    }}
    controller = component.createObject(root, {{ enabled: true, revealDelayMs: 0, hideDelayMs: 0 }})
    controller.revealRequested.connect(function(name, reason) {{ events.push("reveal:" + name + ":" + reason) }})
    controller.concealRequested.connect(function(reason) {{ events.push("conceal:" + reason) }})
    controller.setEligibleScreens(["DP-1", "DP-2"])
    controller.requestImmediateReveal("DP-1", "test", false)
    controller.flyoutHeld = true
    controller.notifyMenuProgress(1)
    controller.setHotZoneHovered("DP-2", true)
    var heldResult = events.slice()
    console.log("BEHAVE " + JSON.stringify({{
      heldResult: heldResult,
      active: controller.activeScreenName,
      queued: controller.queuedScreenName
    }}))
    finish.start()
  }}

  Timer {{ id: finish; interval: 20; onTriggered: Qt.quit() }}
}}
"""
        output = run_quickshell(qml, timeout=8)
        require_no_qml_errors(output)
        row = parse_behave(output)[-1]
        self.assertEqual(["reveal:DP-1:test"], row["heldResult"], output[-3000:])
        self.assertEqual("DP-1", row["active"], output[-3000:])
        self.assertEqual("", row["queued"], output[-3000:])

    def test_fullscreen_and_monitor_removal_cancel_pending_or_active_reveal(self):
        qml = f"""
import Quickshell
import QtQuick

ShellRoot {{
  id: root
  property var controller: null
  property int reveals: 0
  property int conceals: 0

  Component.onCompleted: {{
    var component = Qt.createComponent("{qml_url('lacuna.menu/services/SidebarAutohideController.qml')}", Component.PreferSynchronous)
    if (component.status !== Component.Ready) {{
      console.log("BEHAVE_ERR " + component.errorString())
      Qt.quit()
      return
    }}
    controller = component.createObject(root, {{ enabled: true, revealDelayMs: 40, hideDelayMs: 0 }})
    controller.revealRequested.connect(function() {{ reveals += 1 }})
    controller.concealRequested.connect(function() {{ conceals += 1 }})
    controller.setEligibleScreens(["DP-1"])
    controller.setHotZoneHovered("DP-1", true)
    controller.setScreenSuppressed("DP-1", true)
    probe.restart()
  }}

  Timer {{
    id: probe
    interval: 80
    onTriggered: {{
      controller.setScreenSuppressed("DP-1", false)
      controller.setHotZoneHovered("DP-1", false)
      controller.setHotZoneHovered("DP-1", true)
      controller.requestImmediateReveal("DP-1", "test", false)
      controller.notifyMenuProgress(1)
      controller.setEligibleScreens([])
      console.log("BEHAVE " + JSON.stringify({{
        reveals: reveals,
        conceals: conceals,
        candidate: controller.candidateScreenName,
        phase: controller.phase
      }}))
      Qt.quit()
    }}
  }}
}}
"""
        output = run_quickshell(qml, timeout=8)
        require_no_qml_errors(output)
        row = parse_behave(output)[-1]
        self.assertEqual(1, row["reveals"], output[-3000:])
        self.assertEqual(1, row["conceals"], output[-3000:])
        self.assertEqual("", row["candidate"], output[-3000:])
        self.assertIn(row["phase"], ["hiding", "suppressed"], output[-3000:])


if __name__ == "__main__":
    unittest.main()
