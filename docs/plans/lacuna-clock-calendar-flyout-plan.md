# Lacuna Clock And Calendar Flyout Plan

Status: proposed; decision-complete for implementation

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
  becomes the primary flyout action; existing alternate-format settings remain
  readable for configuration compatibility.

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
- Keep interaction intentionally minimal: no event affordances, inline editor,
  agenda region, week-number column, or timezone dashboard.

## Implementation Changes

- Extend `lacuna.clock/Widget.qml` with explicit `open()`, `close()`, and
  `closeForPopoutSwitch()` behavior and retain the injected `bar`,
  `moduleName`, and `settings` contract.
- Add a plugin-local popup component using `PopupWindow`,
  `HyprlandFocusGrab`, `bar.requestPopout()`, and `bar.releasePopout()` so the
  calendar participates in exclusive top-bar popout ownership and dismisses
  on outside click.
- Add plugin-local calendar calculation helpers that deterministically produce
  42 cells for a visible month, including leading and trailing adjacent-month
  dates and year rollover.
- Build the attached shell with the canonical `LacunaGeometry.curveKappa`, a
  square bar attachment edge, rounded exposed corners, `strokeWidth: 0`, and
  no `Rectangle.radius` on the shell.
- Use the established top/bottom bar anchoring and screen-edge clamping pattern
  from existing Lacuna bar flyouts. The panel should remain a stable compact
  width rather than stretching with localized labels.
- Limit motion to the established flyout reveal and short state transitions.
  Do not add animated backgrounds, ambient effects, or decorative motion.

## Configuration And Compatibility

- Keep `format`, `formatAlt`, and `verticalFormat` accepted so existing
  `shell.json` entries do not become invalid.
- Add separate compact time and compact date format settings only if the final
  two-part bar composition cannot derive them from the existing horizontal
  format without parsing user-provided format strings.
- Use the system's local date, time, timezone, and Qt locale labels. The initial
  grid is Sunday-first unless a locale-safe Qt API already available to the
  plugin can supply the system week convention without a service or script.
- Keep `lacuna.clock` an on-demand, standalone, single-instance `bar-widget`.
  Do not add a service entry point or runtime import outside its plugin
  directory.

## Test And Acceptance Plan

- Add deterministic behavior coverage for leap years, Sunday- and
  Saturday-boundary months, six-week layouts, adjacent-month cells, and
  December/January rollover.
- Add QML behavior coverage for open/close, exclusive popout switching, month
  navigation, date selection, adjacent-month selection, `Today`, outside-click
  dismissal, and clock/date rollover while open.
- Add geometry coverage for the molded bar attachment, fill-only shell, square
  attachment edge, rounded exposed corners, and top/bottom bar placement.
- Extend manifest and QML contract tests for configuration compatibility,
  injected properties, plugin-local dependencies, and the absence of calendar
  backend or event-editing behavior.
- Run `./scripts/check.sh`, then deploy with
  `./scripts/dev deploy lacuna.clock`. Verify the installed copy matches the
  checkout and smoke-test horizontal, compact, vertical, top, and bottom bar
  modes, popout exclusivity, shell restart, current-date rollover, and
  timezone-menu access.

## Completion Boundary

The proposal is complete when the adaptive bar face and read-only visual month
flyout are implemented, covered by deterministic and runtime behavior tests,
deployed into the live Omarchy plugin directory, and verified in the running
shell. Calendar-provider integration remains a separate future product
decision and must not be inferred from this plan.
