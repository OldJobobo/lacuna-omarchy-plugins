# Lacuna Weather Flyout

Status: implemented and live-verified (2026-07-13)

## Outcome

Turn `lacuna.weather` from a command-output pill into a self-contained weather
surface. The bar keeps a compact condition icon and temperature while left
click opens an attached Lacuna flyout with current conditions and three future
days. Middle click forces a refresh. Right click sends a notification assembled
from the same normalized report shown in the flyout.

## Product Boundary

- Show current temperature, condition, location, feels-like temperature, wind,
  and humidity.
- Show exactly three future forecast columns beneath the current-condition hero.
- Infer location by default and support an optional location override.
- Support `auto`, `imperial`, and `metric` temperature units.
- Retain the last good report when an update fails and mark it stale.
- Keep the plugin standalone. It may call public weather endpoints, but it must
  not import from the repository root or start another Quickshell process.
- Do not add radar, severe-alert management, saved-location switching, hourly
  charts, or a weather-provider settings application in this phase.

## Data Contract

`WeatherState.qml` owns refresh timing and request lifecycle. A blank location
uses IP-based approximate geolocation; an override uses Open-Meteo geocoding.
Open-Meteo provides current conditions and the preferred daily forecast, while
`wttr.in` remains a secondary fallback. `WeatherModel.js` performs URL encoding,
unit resolution, icon mapping, report normalization, and notification
formatting.

The default refresh interval is 15 minutes with a one-minute minimum. A failed
request never clears a previously successful report. Requests are keyed by
location and unit settings so a response from an earlier setting cannot replace
the current selection.

## Surface Contract

- Use the authoritative four-edge molded `BarFlyoutSurface` geometry.
- Keep the attachment edge square, all surface shapes fill-only, and all curves
  sourced through the plugin-local `LacunaGeometry` singleton.
- Load frame shadow enablement and offsets from Lacuna runtime settings and keep
  shadow padding off the attached edge.
- Use Tektur for the title and large temperature, with Lacuna title tracking and
  normal telemetry weight. Use the Lacuna mono face for supporting data.
- Coordinate through the bar's single active-popout owner and dismiss on focus
  loss.

## Execution Checklist

- [x] Add normalized current and forecast data ownership.
- [x] Replace command parsing in the bar widget with shared weather state.
- [x] Add left-open, middle-refresh, and right-notification interactions.
- [x] Add the current-condition hero and three-column forecast flyout.
- [x] Add inferred/override location and unit settings to the manifest.
- [x] Add last-good, loading, stale, and unavailable states.
- [x] Add four-edge molding and frame-shadow support.
- [x] Add Lacuna Tektur weight and tracking tokens.
- [x] Add contract, deterministic geometry, and runtime behavior coverage.
- [x] Run the repository validation suite.
- [x] Deploy `lacuna.weather` and verify the installed copy and live shell.

## Validation

Run:

```sh
python3 -m pytest -q tests/test_qml_behavior_weather.py \
  tests/test_qml_behavior_weather_bar_style.py
python3 -m pytest -q tests/test_qml_geometry.py tests/test_qml_contracts.py
./scripts/check.sh
./scripts/dev deploy lacuna.weather
```

Live verification should confirm the top-bar flyout opens, refreshes, shows
current and forecast data, uses the configured frame shadow, and releases the
bar popout owner when dismissed. Deterministic geometry and runtime tests cover
top, bottom, left, and right attachment calculations.

Completion note 2026-07-13: `./scripts/check.sh` passed with 295 tests and 3
expected skips. `./scripts/dev deploy lacuna.weather` restarted Omarchy shell,
verified the installed copy byte-for-byte, and the live bars populated current
Open-Meteo temperatures after the provider fallback was exercised.
