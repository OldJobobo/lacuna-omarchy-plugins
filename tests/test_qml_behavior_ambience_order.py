import struct
import tempfile
import unittest
import zlib
from pathlib import Path

from qml_harness import HAVE_SESSION, parse_behave, qml_url, require_no_qml_errors, run_quickshell


def center_rgb(path: Path) -> tuple[int, int, int]:
    data = path.read_bytes()
    assert data[:8] == b"\x89PNG\r\n\x1a\n"
    offset = 8
    width = height = color_type = None
    payload = bytearray()
    while offset < len(data):
        length = struct.unpack(">I", data[offset:offset + 4])[0]
        kind = data[offset + 4:offset + 8]
        chunk = data[offset + 8:offset + 8 + length]
        offset += 12 + length
        if kind == b"IHDR":
            width, height, depth, color_type, _, _, _ = struct.unpack(">IIBBBBB", chunk)
            assert depth == 8 and color_type in (2, 6)
        elif kind == b"IDAT":
            payload.extend(chunk)
        elif kind == b"IEND":
            break
    channels = 4 if color_type == 6 else 3
    stride = width * channels
    raw = zlib.decompress(bytes(payload))
    rows = []
    previous = bytearray(stride)
    cursor = 0
    for _ in range(height):
        filter_type = raw[cursor]
        cursor += 1
        source = raw[cursor:cursor + stride]
        cursor += stride
        row = bytearray(stride)
        for index, value in enumerate(source):
            left = row[index - channels] if index >= channels else 0
            up = previous[index]
            upper_left = previous[index - channels] if index >= channels else 0
            if filter_type == 0:
                decoded = value
            elif filter_type == 1:
                decoded = value + left
            elif filter_type == 2:
                decoded = value + up
            elif filter_type == 3:
                decoded = value + ((left + up) // 2)
            elif filter_type == 4:
                estimate = left + up - upper_left
                pa, pb, pc = abs(estimate - left), abs(estimate - up), abs(estimate - upper_left)
                predictor = left if pa <= pb and pa <= pc else up if pb <= pc else upper_left
                decoded = value + predictor
            else:
                raise AssertionError(f"unsupported PNG filter {filter_type}")
            row[index] = decoded & 0xFF
        rows.append(row)
        previous = row
    pixel = rows[height // 2][(width // 2) * channels:(width // 2) * channels + 3]
    return tuple(pixel)


@unittest.skipUnless(HAVE_SESSION, "needs a quickshell binary and a Wayland session")
class QmlAmbienceOrderBehaviorTests(unittest.TestCase):
    def test_production_effects_load_only_for_painting_selected_stack(self):
        qml = f'''
import Quickshell
import QtQuick

ShellRoot {{
  Item {{
    id: host
    width: 32
    height: 32

    Loader {{
      id: stackLoader
      anchors.fill: parent
      source: "{qml_url('lacuna.ambience-host/AmbienceStack.qml')}"
      onLoaded: {{
        item.activeEffects = ["auroraDrift", "filmGrain"]
        item.paintEnabled = false
        disabledProbe.restart()
      }}
    }}

    Timer {{
      id: disabledProbe
      interval: 40
      onTriggered: {{
        var stack = stackLoader.item
        host.propertyA = stack.activeProductionEffectCount
        stack.paintEnabled = true
        enabledProbe.restart()
      }}
    }}
    property int propertyA: -1
    property var firstIdentity: null
    property var secondIdentity: null

    Timer {{
      id: enabledProbe
      interval: 120
      onTriggered: {{
        var stack = stackLoader.item
        host.firstIdentity = stack.productionEffectObject("auroraDrift")
        host.secondIdentity = stack.productionEffectObject("filmGrain")
        var enabledCount = stack.activeProductionEffectCount
        stack.activeEffects = ["filmGrain", "auroraDrift"]
        Qt.callLater(function() {{
          console.log("BEHAVE " + JSON.stringify({{
            disabledCount: host.propertyA,
            enabledCount: enabledCount,
            sameFirst: host.firstIdentity === stack.productionEffectObject("auroraDrift"),
            sameSecond: host.secondIdentity === stack.productionEffectObject("filmGrain"),
            frontZ: stack.zForEffect("filmGrain"),
            backZ: stack.zForEffect("auroraDrift")
          }}))
          Qt.quit()
        }})
      }}
    }}
  }}
}}
'''
        output = run_quickshell(qml, timeout=10)
        require_no_qml_errors(output)
        row = parse_behave(output)[-1]
        self.assertEqual(row["disabledCount"], 0, output[-2000:])
        self.assertEqual(row["enabledCount"], 2, output[-2000:])
        self.assertTrue(row["sameFirst"], output[-2000:])
        self.assertTrue(row["sameSecond"], output[-2000:])
        self.assertGreater(row["frontZ"], row["backZ"], output[-2000:])

    def test_reorder_changes_pixel_and_z_without_recreating_stack_objects(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            first = Path(temp_dir) / "front-red.png"
            second = Path(temp_dir) / "front-blue.png"
            qml = f'''
import Quickshell
import QtQuick
import QtQuick.Window

ShellRoot {{
  Window {{
    id: window
    width: 24
    height: 24
    visible: true
    color: "black"

    Component {{ id: redLayer; Rectangle {{ color: "#80ff0000" }} }}
    Component {{ id: blueLayer; Rectangle {{ color: "#800000ff" }} }}

    Loader {{
      id: stackLoader
      anchors.fill: parent
      source: "{qml_url('lacuna.ambience-host/AmbienceStack.qml')}"
      onLoaded: {{
        item.productionEffectsEnabled = false
        item.testFrontComponent = redLayer
        item.testBackComponent = blueLayer
        item.activeEffects = ["auroraDrift", "unknown", "filmGrain", "auroraDrift"]
        probe.restart()
      }}
    }}

    Timer {{
      id: probe
      interval: 80
      repeat: false
      onTriggered: {{
        var stack = stackLoader.item
        var frontIdentity = stack.testFrontObject
        var backIdentity = stack.testBackObject
        var initialNormalized = stack.normalizedActiveEffects
        var firstFrontZ = stack.zForEffect("auroraDrift")
        var firstBackZ = stack.zForEffect("filmGrain")
        stack.grabToImage(function(result) {{
          result.saveToFile("{first}")
          stack.activeEffects = ["filmGrain", "auroraDrift"]
          Qt.callLater(function() {{
            var secondFrontZ = stack.zForEffect("filmGrain")
            var secondBackZ = stack.zForEffect("auroraDrift")
            stack.grabToImage(function(secondResult) {{
              secondResult.saveToFile("{second}")
              console.log("BEHAVE " + JSON.stringify({{
                initialNormalized: initialNormalized,
                firstFrontZ: firstFrontZ,
                firstBackZ: firstBackZ,
                secondFrontZ: secondFrontZ,
                secondBackZ: secondBackZ,
                sameFrontObject: frontIdentity === stack.testFrontObject,
                sameBackObject: backIdentity === stack.testBackObject,
                normalized: stack.normalizedActiveEffects
              }}))
              Qt.quit()
            }})
          }})
        }})
      }}
    }}
  }}
}}
'''
            output = run_quickshell(qml, timeout=10)
            require_no_qml_errors(output)
            row = parse_behave(output)[0]
            self.assertEqual(row["initialNormalized"], ["auroraDrift", "filmGrain"], output[-2000:])
            self.assertGreater(row["firstFrontZ"], row["firstBackZ"], output[-2000:])
            self.assertGreater(row["secondFrontZ"], row["secondBackZ"], output[-2000:])
            self.assertTrue(row["sameFrontObject"], output[-2000:])
            self.assertTrue(row["sameBackObject"], output[-2000:])
            self.assertEqual(row["normalized"], ["filmGrain", "auroraDrift"], output[-2000:])
            first_rgb = center_rgb(first)
            second_rgb = center_rgb(second)
            self.assertGreater(first_rgb[0], first_rgb[2], (first_rgb, second_rgb, output[-2000:]))
            self.assertGreater(second_rgb[2], second_rgb[0], (first_rgb, second_rgb, output[-2000:]))


if __name__ == "__main__":
    unittest.main()
