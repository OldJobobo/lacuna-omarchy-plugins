# Plugin Contracts

Status: reference

Lacuna plugins follow Omarchy's plugin contracts and keep runtime imports
self-contained under each plugin directory.

## Directory Contract

Plugin directories live at the repository root as `lacuna.*` directories. This
is intentional: Omarchy's repo-source installer scans only top-level folders
that contain a `manifest.json`.

Keep plugin code self-contained under its plugin directory. Do not depend on
the repository root as a runtime import path.

## Entry Points

- Bar widgets expose an `Item`, usually through `Widget.qml`.
- Menu and panel surfaces implement `open(payloadJson)` and `close()`.
- `lacuna.bar` is a bar option selected through `bar.id`, not a bar widget
  placed in `bar.layout`.

## Injection

Bar widgets should accept the injected properties:

- `property var bar`
- `property string moduleName`
- `property var settings`

Simple bar widgets do not receive a `shell` reference. If they need live system
state, they should read appropriate `Quickshell.Services.*` APIs directly.
Menu, bar, service, and panel plugins can use the injected `shell` reference
and Omarchy services where available.

## Vendored Helpers

`shared/qml/simple-bar/` is the canonical source for helper templates used by
simple Lacuna topbar widgets. `scripts/sync-vendored` keeps plugin-local copies
in sync. Runtime plugins should not import from `shared/`.

## Metadata

Every plugin manifest includes a `lacuna` metadata block for Lacuna tests,
docs, and future tooling. Omarchy ignores this metadata when validating or
installing plugins. See `docs/plugins/README.md`.
