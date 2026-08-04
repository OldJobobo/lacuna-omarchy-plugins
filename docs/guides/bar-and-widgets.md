# Bar and widgets

Status: user guide for the latest beta

Lacuna's bar is the structural top or side of the connected shell. It hosts a
curated set of launch, workspace, time, weather, system, theme, media, and
status controls.

## Use the default layout first

The normal installer applies the canonical bar layout and selects Lacuna's bar
host. You do not need to add individual plugin IDs after a full installation.

Widgets may hide as a whole when a horizontal bar becomes too narrow. Lacuna
keeps the centered module aligned to the physical output center and protects
left and right sections from overlapping it. Hidden widgets return when space
is available.

## Change placement or widget options

Open **Omarchy Settings** to change:

- bar edge and size;
- layout and widget order;
- options exposed by individual widgets.

Open **Lacuna Settings** for shell-wide appearance, frame, sidebar, application,
media, and ambience choices. See [Configuration ownership](../configuration/index.md).

## Full, compact, and theme sizing

The bar-size control switches between supported density choices. Responsive
hiding is separate from density: choosing full mode does not force every widget
to fit on a narrow screen.

The Lacuna bar is intentionally opaque. Its bar, frame, sidebar, connectors,
and flyouts are designed as one surface, so Omarchy's stock-bar transparency
gesture is not part of this bar.

## Portrait screens

A portrait output with a top or bottom bar uses the portrait split presentation
by default. Selected status widgets move to a companion band on the opposite
edge; other widgets remain in the primary bar. There is still one canonical
layout to edit.

See [Multiple monitors](multiple-monitors.md) to change this advanced behavior.

## Add an a-la-carte widget

Individual Lacuna widgets can be installed and placed through Omarchy's plugin
workflow, but this is advanced use. Check the
[plugin catalog](../plugins/README.md) for stability and companion requirements,
then use Omarchy Settings to place the widget. Do not install bundle-only
services as if they were standalone widgets.
