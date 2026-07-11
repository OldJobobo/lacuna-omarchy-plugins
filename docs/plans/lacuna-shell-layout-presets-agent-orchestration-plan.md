# Lacuna Shell Layout Presets and Agent Orchestration Mode

Status: proposed

## Summary

Introduce a preset engine that changes Lacuna's complete shell presentation
without rewriting the user's underlying Omarchy bar configuration. The MVP
ships two built-in profiles:

- **Standard Lacuna:** preserves the current frame, bar, and sidebar behavior.
- **Agent Orchestration:** removes frame paint and reserves, replaces the
  full-width painted bar with a centered island, and converts the sidebar into
  an offscreen auto-hide Agent Orchestration dashboard.

Presets resolve independently per monitor from its active Hyprland workspace.
Resolution order is: exact monitor/workspace override, monitor-wide override,
workspace-wide override, then global default.

## Implementation Changes

### Preset runtime and persistence

- Extend Lacuna settings with a versioned `layoutPresets` section containing
  the global default and assignment rules. Preserve unknown fields during
  normalization and migration.
- Add a central preset resolver to `lacuna.state`, exposing the effective
  preset for a given monitor and workspace.
- Keep presets structural and authoritative while active. Existing cosmetic
  settings and compatible widget settings remain editable; conflicting frame,
  sidebar, and bar-structure controls are disabled with an explanation.
- Treat built-in preset definitions as code-owned and immutable in the MVP,
  while keeping their normalized interface suitable for future user-authored
  presets.
- Never rewrite `shell.json` during workspace switching. Apply profile behavior
  as a runtime presentation layer over the existing bar configuration.

### Per-monitor shell composition

- Resolve each monitor's profile from that monitor's active workspace, not
  merely the globally focused workspace.
- Keep existing layer-shell windows permanently mapped where required by the
  stacking policy. Animate painted content and geometry without
  visibility-driven remapping.
- For Agent Orchestration:
  - Disable full-frame paint, border, shadow, and exclusive frame reserves.
  - Keep a full-width transparent bar window but render and accept input only
    within a centered rounded island.
  - Populate the island with the workspace switcher, preset/sidebar control,
    compact Codex and Claude activity, clock, weather, and compatible modules
    from the user's existing center layout, deduplicated into a curated preset
    order.
  - Preserve existing widget-specific settings inside the island.
- Add a short coordinated fade/slide transition when a monitor changes
  effective presets, with geometry and input state switching at a deterministic
  transition boundary.

### Auto-hide orchestration sidebar

- Preserve one hosted sidebar instance; it adopts the effective preset and
  target screen of the monitor that invoked or revealed it.
- Add a narrow left-edge activation zone on Agent Orchestration monitors:
  - Reveal after a short hover dwell.
  - Keep open while the pointer, keyboard focus, or a flyout is inside.
  - Hide after a brief leave delay.
  - Also support the island control and existing menu toggle path.
- The sidebar starts on a new `agent-orchestration` root view instead of
  `main`.
- Standard Lacuna keeps its existing sidebar defaults and navigation stack.
- Switching away from Agent Orchestration closes its transient flyouts and
  restores the destination profile's sidebar state without overwriting
  persistent user preferences.

### Agent Orchestration dashboard

- Add normalized Codex and Claude provider adapters that report:
  - Provider and running/recent status.
  - Project or working directory.
  - Session recency and safe usage/status metadata.
  - Whether the session was launched by Lacuna and can be focused reliably.
- Do not expose conversation or prompt contents.
- Dashboard actions:
  - Launch a new Codex or Claude terminal in a selected recent project.
  - Focus an existing Lacuna-launched terminal using a stable title/class
    marker and Hyprland client matching.
  - For externally launched sessions that cannot be mapped safely to a window,
    show status without a misleading Focus action.
- Poll providers conservatively and retain the last valid snapshot through
  temporary command or parse failures.
- Show explicit empty, unavailable, loading, and stale-data states.

### Settings interface

- Add a Layout Presets section with:
  - Global default preset.
  - Monitor-wide assignments.
  - Workspace-wide assignments.
  - Exact monitor/workspace overrides.
  - A clear indication of the currently effective rule and preset.
- Populate monitor choices from live outputs and workspace choices from
  Hyprland state.
- Retain assignments for disconnected monitors, label them unavailable, and
  fall back through the precedence chain.
- Provide preset switching through Settings and the orchestration island
  control.

## Public Interfaces

- Persist a normalized settings shape equivalent to:
  - `layoutPresets.defaultPreset`
  - `layoutPresets.assignments[]` with `monitor`, `workspace`, and `preset`
- Expose resolver methods equivalent to:
  - `presetFor(monitorName, workspaceId)`
  - `effectivePresetForScreen(screen)`
- Define a normalized agent record shared by both providers, including
  provider, session identity, project, activity state, timestamps, focus
  capability, and launch metadata.
- Add `agent-orchestration` to the sidebar registry as a first-class root view.

## Test Plan

- Unit-test settings migration, malformed assignments, disconnected monitors,
  and assignment precedence.
- Add deterministic behavior tests for per-monitor preset resolution as
  workspaces move or focus changes.
- Test that Agent Orchestration disables frame paint and reserves without
  changing stored Standard Lacuna settings.
- Test island module filtering, ordering, deduplication, and existing
  widget-setting reuse.
- Add runtime QML tests for edge dwell, leave delay, flyout hold-open behavior,
  sidebar target-monitor selection, default orchestration view, and transition
  state.
- Test Codex and Claude provider parsing with running, recent, missing,
  malformed, and stale session fixtures.
- Test that Focus appears only for reliably associated terminal windows.
- Extend layer-stacking contracts for any new surfaces and verify that preset
  transitions do not remap protected surfaces.
- Run `./scripts/check.sh`, then deploy `lacuna.state`, `lacuna.bar`, and
  `lacuna.menu` with `./scripts/dev deploy --all --only-changed`.
- Live-verify mixed layouts across at least two monitors: Standard on one
  monitor, Agent Orchestration on another, workspace transitions, edge reveal,
  island controls, shell restart persistence, and fallback after disconnecting
  an assigned monitor.

## Assumptions

- The MVP supports built-in presets only; custom preset authoring follows
  later.
- Workspace IDs are matched together with monitor names, allowing the same
  workspace number to resolve differently on different outputs.
- Standard Lacuna remains the safe fallback for unknown or invalid preset IDs.
- The MVP supports Codex and Claude Code and limits controls to observe, launch,
  and focus—no messaging, stopping, or restarting agent processes.
- Existing unrelated working-tree changes remain outside this feature.
