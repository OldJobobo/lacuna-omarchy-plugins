# Lacuna Clock And Calendar Flyout Plan

Status: proposed; decision-complete for implementation after geometry and
compatibility review

## Summary

Transform `lacuna.clock` into a first-class time-and-calendar bar widget. The
bar presents the current time with a compact date; left-click opens a polished,
read-only month calendar. Quality comes from adaptive typography, clear date
hierarchy, precise interaction, and Lacuna's molded attachment geometry rather
than organizer features.

Events, agendas, reminders, event editing, and external calendar backends are
out of scope.

## Product Behavior

### Bar face

- Horizontal bars show a strong time readout with a restrained weekday/day
  companion.
- Compact horizontal bars tighten typography and spacing without dropping the
  date.
- Vertical bars retain a rotated vertical treatment compatible with the
  existing `verticalFormat` setting.
- Left-click opens or closes the calendar flyout. Right-click retains the
  timezone menu.
- The current alternate-format click behavior is retired because left-click
  becomes the primary flyout action. Existing `formatAlt` values are tolerated
  as ignored legacy data but are no longer presented as an editable setting.

### Calendar flyout

- Use a hero header containing the current time, full current or selected
  date, month, and year.
- Render weekday headings above a fixed seven-column, six-row month grid so the
  flyout does not resize between months.
- Give today the strongest accent treatment, the selected date a quieter
  secondary treatment, and adjacent-month dates subdued contrast.
- Provide previous-month, next-month, and `Today` controls. Clicking an
  adjacent-month date changes the visible month and selects that date.
- Date selection updates the hero date without launching another application
  or producing side effects.
- Preserve the viewed month and selected date while the plugin instance stays
  loaded. `Today` restores the live date and current month.
- At local midnight, update the live clock and today highlight immediately. If
  the user has selected another date or navigated away from the current month,
  preserve that selection and view; otherwise advance the selected date and
  visible month to the new today.
- Keep interaction intentionally minimal: no event affordances, inline editor,
  agenda region, week-number column, or timezone dashboard.

## Implementation Changes

- Treat the current `lacuna.clock/Widget.qml` as the implementation baseline.
  Preserve its split date/time typography, semantic date color, foreground time
  color, seam, sizing, and injected `bar`, `moduleName`, and `settings`
  contract. Do not reapply the older single-label implementation over that
  work.
- Replace the `alt` click state with `flyoutOpen` and expose `opened`, `open()`,
  `close()`, `closeForPopoutSwitch()`, and `toggleFlyout()` on `Widget.qml`.
  Update the existing clock bar behavior test so it protects the retained
  split typography without expecting alternate-format toggling.
- Add `CalendarFlyout.qml` as a plugin-local `PopupWindow` using
  `HyprlandFocusGrab` for outside-click dismissal. Define
  `coordinatorKey: owner || root`; the popup must call
  `bar.requestPopout(coordinatorKey, anchorItem, owner ? owner.moduleName : "")`
  and release that same key. This makes the widget's
  `closeForPopoutSwitch()` the method the bar coordinator invokes and prevents
  stale `activePopout` ownership.
- Add plugin-local calendar calculation helpers that deterministically produce
  42 cells for a visible month, including leading and trailing adjacent-month
  dates and year rollover. Construct calendar dates at local noon and compare
  normalized year/month/day tuples so daylight-saving transitions cannot shift
  a cell into the previous or next day.
- Add an orientation-aware plugin-local bar flyout surface using the canonical
  `LacunaGeometry.curveKappa`, a square bar attachment edge, rounded exposed
  corners, `strokeWidth: 0`, and no `Rectangle.radius` on the shell. Do not copy
  an existing top-attached `BarFlyoutSurface.qml` unchanged.
- Support all four bar positions with one explicit attachment-edge contract:

  | Bar position | Flyout placement | Attached square edge | Rounded exposed edge |
  | --- | --- | --- | --- |
  | `top` | below the bar | top | bottom corners |
  | `bottom` | above the bar | bottom | top corners |
  | `left` | right of the bar | left | right corners |
  | `right` | left of the bar | right | left corners |

  Mirror or rotate both the molding connector and reveal clip for the selected
  edge. Screen clamping operates on the axis parallel to the bar: horizontal
  clamping for top/bottom bars and vertical clamping for left/right bars. The
  panel remains a stable compact size rather than stretching with localized
  labels.
- Limit motion to the established flyout reveal and short state transitions.
  Do not add animated backgrounds, ambient effects, or decorative motion.

## Configuration And Compatibility

- Keep `format` and `verticalFormat` as supported compatibility settings. Add
  explicit `dateFormat` and `timeFormat` settings for the two-part horizontal
  face; compact mode uses the same formats with tighter typography and spacing,
  so it does not add another pair of format settings. When the explicit keys
  are absent in an older configuration, derive them with the existing
  `dateFormatPart()` and `timeFormatPart()` compatibility helpers and fall back
  to `ddd d` and `h:mm AP` if the legacy value cannot be split.
- Retire `formatAlt` without destructive migration: remove it from
  `lacuna.clock/manifest.json` defaults and schema, `scripts/lacuna`, example
  shell configuration, and installer expectations. Continue to tolerate and
  ignore an existing inline `formatAlt` key; settings writes must preserve that
  unknown key instead of deleting it from the user's `shell.json`.
- Use the system's local date, time, and timezone plus Qt locale labels. Version
  one is explicitly Sunday-first on every locale; weekday labels are localized
  and reordered into Sunday-through-Saturday order. Locale-derived week starts
  are deferred until they can be added as an explicit, tested product setting.
- Keep `lacuna.clock` an on-demand, standalone, single-instance `bar-widget`.
  Do not add a service entry point or runtime import outside its plugin
  directory.

## Test And Acceptance Plan

- Add deterministic behavior coverage for leap years, Sunday- and
  Saturday-boundary months, six-week layouts, adjacent-month cells, and
  December/January rollover. Include a daylight-saving boundary fixture and
  assert the fixed Sunday-first column order independently of the host locale.
- Add QML behavior coverage for open/close, exclusive popout switching, month
  navigation, date selection, adjacent-month selection, `Today`, outside-click
  dismissal, and clock/date rollover while open. Assert the coordinator key is
  requested and released symmetrically and that popout switching reaches the
  widget's `closeForPopoutSwitch()`.
- Add geometry coverage for the molded bar attachment, fill-only shell, square
  attachment edge, rounded exposed corners, and top, bottom, left, and right bar
  placement. Each orientation must assert the correct attached edge, exposed
  corners, reveal direction, and clamping axis.
- Extend manifest and QML contract tests for configuration compatibility,
  injected properties, plugin-local dependencies, legacy `formatAlt`
  tolerance, explicit date/time formats, and the absence of calendar backend or
  event-editing behavior.
- Run `./scripts/check.sh`, then deploy with
  `./scripts/dev deploy lacuna.clock`. Verify the installed copy matches the
  checkout and smoke-test horizontal, compact, top, bottom, left, and right bar
  modes, popout exclusivity, outside-click dismissal, shell restart,
  current-date rollover, and timezone-menu access.

## Completion Boundary

The proposal is complete when the adaptive bar face and read-only visual month
flyout are implemented, covered by deterministic and runtime behavior tests,
deployed into the live Omarchy plugin directory, and verified in the running
shell. Calendar-provider integration remains a separate future product
decision and must not be inferred from this plan.
