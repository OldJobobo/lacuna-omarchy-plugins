import json
import re
import unittest

from qml_harness import qml_url, run_quickshell


class QmlSystemStatsBehaviorTests(unittest.TestCase):
    def test_shared_service_stops_polling_without_consumers(self):
        qml = f'''
import Quickshell
import QtQuick

ShellRoot {{
  Component.onCompleted: {{
    var component = Qt.createComponent("{qml_url('lacuna.system-stats/Service.qml')}", Component.PreferSynchronous)
    if (component.status !== Component.Ready) {{
      console.log("BEHAVE " + JSON.stringify({{ error: component.errorString() }}))
      Qt.quit()
      return
    }}
    var service = component.createObject(root)
    var consumer = consumerComponent.createObject(root)
    var initial = service.snapshotLaunchCount
    service.subscribe(consumer)
    observe.service = service
    observe.consumer = consumer
    observe.initial = initial
    observe.start()
  }}

  id: root

  Component {{
    id: consumerComponent
    QtObject {{ property int intervalMs: 1000 }}
  }}

  Timer {{
    id: observe
    property var service
    property var consumer
    property int initial: 0
    interval: 1400
    onTriggered: {{
      var subscribedLaunches = service.snapshotLaunchCount
      service.unsubscribe(consumer)
      var stoppedAt = service.snapshotLaunchCount
      settle.service = service
      settle.initial = initial
      settle.subscribedLaunches = subscribedLaunches
      settle.stoppedAt = stoppedAt
      settle.start()
    }}
  }}

  Timer {{
    id: settle
    property var service
    property int initial: 0
    property int subscribedLaunches: 0
    property int stoppedAt: 0
    interval: 1250
    onTriggered: {{
      console.log("BEHAVE " + JSON.stringify({{
        initial: initial,
        subscribedLaunches: subscribedLaunches,
        stoppedAt: stoppedAt,
        finalLaunches: service.snapshotLaunchCount,
        consumers: service.consumerCount,
        polling: service.polling
      }}))
      Qt.quit()
    }}
  }}
}}
'''
        output = run_quickshell(qml, timeout=8)
        match = re.search(r"BEHAVE (\{.*\})", output)
        self.assertIsNotNone(match, output)
        row = json.loads(match.group(1))
        self.assertNotIn("error", row)
        self.assertGreater(row["subscribedLaunches"], row["initial"])
        self.assertEqual(row["stoppedAt"], row["finalLaunches"])
        self.assertEqual(0, row["consumers"])
        self.assertFalse(row["polling"])


if __name__ == "__main__":
    unittest.main()
