import json
import unittest
from datetime import date, timedelta

from qml_harness import HAVE_SESSION, parse_behave, qml_url, require_no_qml_errors, run_quickshell


@unittest.skipUnless(HAVE_SESSION, "needs a quickshell binary and a Wayland session")
class QmlWeatherBehaviorTests(unittest.TestCase):
    def test_reports_preserve_last_good_data_and_prefer_daily_forecast(self):
        today = date.today()
        forecast_dates = [(today + timedelta(days=offset)).isoformat() for offset in range(1, 4)]
        report = {
            "current_condition": [{
                "temp_F": "66", "temp_C": "19", "FeelsLikeF": "65", "FeelsLikeC": "18",
                "weatherCode": "113", "weatherDesc": [{"value": "Sunny"}],
                "windspeedMiles": "5", "windspeedKmph": "8", "humidity": "42",
            }],
            "nearest_area": [{
                "areaName": [{"value": "Seattle"}],
                "country": [{"value": "United States"}],
            }],
            "weather": [
                {
                    "date": day,
                    "maxtempF": str(70 + index), "mintempF": str(52 + index),
                    "maxtempC": str(21 + index), "mintempC": str(11 + index),
                    "hourly": [{"time": "1200", "weatherCode": "116"}],
                }
                for index, day in enumerate(forecast_dates)
            ],
        }
        daily = {
            "current": {
                "temperature_2m": 23,
                "apparent_temperature": 22,
                "relative_humidity_2m": 44,
                "weather_code": 0,
                "wind_speed_10m": 8,
            },
            "daily": {
                "time": forecast_dates,
                "temperature_2m_max": [25, 22, 18],
                "temperature_2m_min": [14, 12, 9],
                "weather_code": [0, 61, 3],
            }
        }
        report_json = json.dumps(json.dumps(report))
        daily_json = json.dumps(json.dumps(daily))
        qml = f"""
import Quickshell
import QtQuick

ShellRoot {{
  property var state: null

  Timer {{
    interval: 20
    running: true
    repeat: false
    onTriggered: {{
    var component = Qt.createComponent("{qml_url('lacuna.weather/WeatherState.qml')}", Component.PreferSynchronous)
    state = component.createObject(this, {{
      autoRefresh: false,
      settings: {{ location: "Seattle", unit: "imperial", interval: 900000 }}
    }})
    state.activeWeatherKey = state.requestKey
    state.finishWeatherRequest({report_json})
    var fallbackTemperature = state.current.temperature
    var fallbackDescription = state.current.description
    var wttrFirstHigh = state.forecastTemperature(state.forecastDays[0], "max")
    state.activeDailyKey = state.requestKey
    state.finishDailyRequest({daily_json})
    var preferredFirstHigh = state.forecastTemperature(state.forecastDays[0], "max")
    state.resolvedLocation = {{
      latitude: 47.6062, longitude: -122.3321,
      name: "Seattle", region: "Washington", country: "United States"
    }}
    state.finishOpenMeteoRequest({daily_json})
    var primaryTemperature = state.current.temperature
    var primaryDescription = state.current.description
    state.activeWeatherKey = state.requestKey
    state.finishWeatherRequest("not json")

    console.log("BEHAVE " + JSON.stringify({{
      location: state.current.location,
      temperature: state.current.temperature,
      barLabel: state.barLabel,
      description: state.current.description,
      forecastCount: state.forecastDays.length,
      wttrFirstHigh: wttrFirstHigh,
      preferredFirstHigh: preferredFirstHigh,
      primaryTemperature: primaryTemperature,
      primaryDescription: primaryDescription,
      fallbackTemperature: fallbackTemperature,
      fallbackDescription: fallbackDescription,
      stale: state.stale,
      retainedData: state.hasData,
      status: state.statusLabel,
      error: state.errorText,
      notification: state.notificationText()
    }}))
    Qt.quit()
    }}
  }}
}}
"""
        output = run_quickshell(qml, timeout=8)
        require_no_qml_errors(output)
        result = parse_behave(output)[-1]

        self.assertEqual("Seattle", result["location"])
        self.assertEqual("73°F", result["temperature"])
        self.assertEqual("73° F", result["barLabel"])
        self.assertEqual("Clear sky", result["description"])
        self.assertEqual(3, result["forecastCount"])
        self.assertEqual("70°F", result["wttrFirstHigh"])
        self.assertEqual("77°F", result["preferredFirstHigh"])
        self.assertEqual("73°F", result["primaryTemperature"])
        self.assertEqual("Clear sky", result["primaryDescription"])
        self.assertEqual("66°F", result["fallbackTemperature"])
        self.assertEqual("Sunny", result["fallbackDescription"])
        self.assertTrue(result["stale"])
        self.assertTrue(result["retainedData"])
        self.assertEqual("STALE", result["status"])
        self.assertIn("last report", result["error"])
        self.assertIn("Seattle · Clear sky · 73°F", result["notification"])

    def test_frame_shadow_typography_and_content_fit_all_edges(self):
        qml = f"""
import Quickshell
import QtQuick

ShellRoot {{
  property var flyout: null
  Item {{ id: anchorItem; width: 100; height: 32 }}

  QtObject {{
    id: mockBar
    property string position: "top"
    property color foreground: "#eeeeee"
    property color background: "#101010"
    property color urgent: "#ef1234"
    property string fontFamily: "Hack Nerd Font Propo"
    property var activePopout: null
    function requestPopout(owner, anchor, moduleId) {{ activePopout = owner }}
    function releasePopout(owner) {{ if (activePopout === owner) activePopout = null }}
  }}

  QtObject {{
    id: mockWeather
    property bool hasData: true
    property bool loading: false
    property bool stale: false
    property string errorText: ""
    property string statusLabel: "LIVE"
    property date lastUpdated: new Date()
    property var current: ({{
      icon: "", temperature: "66°F", description: "Sunny", location: "Seattle",
      feelsLike: "65°F", wind: "5 mph", humidity: "42%"
    }})
    property var forecastDays: [{{}}, {{}}, {{}}]
    function refresh(force) {{}}
    function forecastDayName(day) {{ return "Mon" }}
    function forecastTemperature(day, kind) {{ return kind === "max" ? "70°F" : "52°F" }}
  }}

  Timer {{
    interval: 20
    running: true
    repeat: false
    onTriggered: {{
    var component = Qt.createComponent("{qml_url('lacuna.weather/WeatherFlyout.qml')}", Component.PreferSynchronous)
    flyout = component.createObject(this, {{ anchorItem: anchorItem, bar: mockBar, weatherState: mockWeather }})
    flyout.loadFrameSettings('{{"frame":{{"shadow":true,"shadowOffsetX":2,"shadowOffsetY":3}}}}')
    function margins() {{
      return {{ left: flyout.shadowLeftMargin, right: flyout.shadowRightMargin,
        top: flyout.shadowTopMargin, bottom: flyout.shadowBottomMargin }}
    }}
    var top = margins()
    mockBar.position = "bottom"; var bottom = margins()
    mockBar.position = "left"; var left = margins()
    mockBar.position = "right"; var right = margins()
    flyout.loadFrameSettings("invalid json")
    console.log("BEHAVE " + JSON.stringify({{
      top: top, bottom: bottom, left: left, right: right,
      font: flyout.displayFontFamily,
      normalHero: flyout.displayHeroWeight === Font.Normal,
      tracking: flyout.displayTitleTracking,
      contentFits: flyout.contentFitsPanel,
      contentBottom: flyout.contentPadding + flyout.weatherContentHeight,
      panelBottom: flyout.panelHeight - flyout.contentPadding,
      invalidDisablesShadow: !flyout.shadowEnabled
    }}))
    Qt.quit()
    }}
  }}
}}
"""
        output = run_quickshell(qml, timeout=8)
        require_no_qml_errors(output)
        result = parse_behave(output)[-1]

        self.assertEqual({"left": 31, "right": 31, "top": 0, "bottom": 51}, result["top"])
        self.assertEqual({"left": 31, "right": 31, "top": 48, "bottom": 0}, result["bottom"])
        self.assertEqual({"left": 0, "right": 50, "top": 31, "bottom": 31}, result["left"])
        self.assertEqual({"left": 48, "right": 0, "top": 31, "bottom": 31}, result["right"])
        self.assertEqual("Tektur", result["font"])
        self.assertTrue(result["normalHero"])
        self.assertEqual(2.0, result["tracking"])
        self.assertTrue(result["contentFits"])
        self.assertLessEqual(result["contentBottom"], result["panelBottom"])
        self.assertTrue(result["invalidDisablesShadow"])

    def test_widget_open_close_and_popout_switch_use_owner_key(self):
        qml = f"""
import Quickshell
import QtQuick

ShellRoot {{
  property var widget: null
  QtObject {{
    id: mockBar
    property bool vertical: false
    property string position: "top"
    property int barSize: 26
    property color foreground: "#eeeeee"
    property color background: "#101010"
    property color urgent: "#ef1234"
    property string fontFamily: "Hack Nerd Font Propo"
    property var activePopout: null
    property int requestCount: 0
    property int releaseCount: 0
    property string requestedModule: ""
    function showTooltip(owner, text) {{}}
    function hideTooltip(owner) {{}}
    function run(command) {{}}
    function requestPopout(owner, anchor, moduleId) {{
      requestCount++; requestedModule = moduleId
      if (activePopout && activePopout !== owner) activePopout.closeForPopoutSwitch()
      activePopout = owner
    }}
    function releasePopout(owner) {{
      if (activePopout === owner) {{ releaseCount++; activePopout = null }}
    }}
  }}

  Timer {{
    interval: 20
    running: true
    repeat: false
    onTriggered: {{
    var component = Qt.createComponent("{qml_url('lacuna.weather/Widget.qml')}", Component.PreferSynchronous)
    widget = component.createObject(this, {{ bar: mockBar, moduleName: "lacuna.weather", autoRefresh: false }})
    widget.open()
    var opened = widget.opened
    var ownerWasWidget = mockBar.activePopout === widget
    mockBar.activePopout.closeForPopoutSwitch()
    var closedBySwitch = !widget.opened
    widget.open(); widget.close()
    console.log("BEHAVE " + JSON.stringify({{
      opened: opened, ownerWasWidget: ownerWasWidget, closedBySwitch: closedBySwitch,
      requestCount: mockBar.requestCount, releaseCount: mockBar.releaseCount,
      requestedModule: mockBar.requestedModule, activeReleased: mockBar.activePopout === null
    }}))
    Qt.quit()
    }}
  }}
}}
"""
        output = run_quickshell(qml, timeout=8)
        require_no_qml_errors(output)
        result = parse_behave(output)[-1]

        self.assertTrue(result["opened"])
        self.assertTrue(result["ownerWasWidget"])
        self.assertTrue(result["closedBySwitch"])
        self.assertEqual(2, result["requestCount"])
        self.assertEqual(2, result["releaseCount"])
        self.assertEqual("lacuna.weather", result["requestedModule"])
        self.assertTrue(result["activeReleased"])


if __name__ == "__main__":
    unittest.main()
