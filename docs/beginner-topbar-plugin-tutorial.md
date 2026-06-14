# Beginner Guide: Make a Tiny Omarchy Topbar Plugin

Status: reference

This makes the smallest useful Omarchy topbar plugin: a widget that shows
`hello` in the bar. No CPU stats, scripts, assets, or Lacuna styling.

## 1. Create the Plugin Folder

User plugins live here:

```text
~/.config/omarchy/plugins/
```

Create a new plugin folder:

```bash
mkdir -p ~/.config/omarchy/plugins/omarchy.example-hello
cd ~/.config/omarchy/plugins/omarchy.example-hello
```

Your plugin will have two files:

```text
omarchy.example-hello/
  manifest.json
  Widget.qml
```

## 2. Create `manifest.json`

Create this file:

```json
{
  "schemaVersion": 1,
  "id": "omarchy.example-hello",
  "name": "Example Hello",
  "version": "0.1.0",
  "author": "You",
  "description": "A tiny hello widget for the Omarchy topbar.",
  "kinds": ["bar-widget"],
  "entryPoints": {
    "barWidget": "Widget.qml"
  },
  "barWidget": {
    "displayName": "Example Hello",
    "category": "Examples",
    "allowMultiple": false
  }
}
```

What matters:

- `id` is the name you will put in `shell.json`.
- `kinds` tells Omarchy this is a topbar widget.
- `entryPoints.barWidget` points to the QML file to load.

## 3. Create `Widget.qml`

Create this file:

```qml
import QtQuick

Item {
  id: root

  property var bar: null
  property string moduleName: "omarchy.example-hello"
  property var settings: ({})

  implicitWidth: label.implicitWidth + 16
  implicitHeight: bar ? bar.barSize : 26

  Text {
    id: label
    anchors.centerIn: parent
    text: "hello"
    color: bar ? bar.foreground : "white"
    font.family: bar ? bar.fontFamily : "monospace"
    font.pixelSize: 14
  }
}
```

Omarchy fills in these properties:

- `bar`: access to bar colors, font, size, helpers, and position.
- `moduleName`: the widget id.
- `settings`: options from the widget's `shell.json` entry.

`implicitWidth` and `implicitHeight` tell the bar how much space to reserve.

## 4. Tell Omarchy to Find the Plugin

Ask the running shell to rescan plugins:

```bash
omarchy plugin rescan
```

If the widget does not appear later, restart the shell:

```bash
omarchy restart shell
```

## 5. Add It to the Topbar

Open:

```text
~/.config/omarchy/shell.json
```

Find `bar.layout`. Add this object to `left`, `center`, or `right`:

```json
{ "id": "omarchy.example-hello" }
```

Example right-side layout:

```json
"right": [
  { "id": "Tray" },
  { "id": "omarchy.example-hello" }
]
```

Save the file. Omarchy usually hot-reloads `shell.json`. If it does not, run:

```bash
omarchy restart shell
```

You should see `hello` in the topbar.

## 6. Optional: Add a Tooltip

Once the basic widget works, replace `Widget.qml` with this slightly improved
version:

```qml
import QtQuick

Item {
  id: root

  property var bar: null
  property string moduleName: "omarchy.example-hello"
  property var settings: ({})

  implicitWidth: label.implicitWidth + 16
  implicitHeight: bar ? bar.barSize : 26
  readonly property bool tooltipHovered: mouseArea.containsMouse

  Text {
    id: label
    anchors.centerIn: parent
    text: "hello"
    color: bar ? bar.foreground : "white"
    font.family: bar ? bar.fontFamily : "monospace"
    font.pixelSize: 14
  }

  MouseArea {
    id: mouseArea

    anchors.fill: parent
    hoverEnabled: true
    onEntered: if (bar) bar.showTooltip(root, "Hello from an Omarchy plugin")
    onExited: if (bar) bar.hideTooltip(root)
  }
}
```

This is the next common pattern: use `MouseArea` for interaction and Omarchy's
shared tooltip helpers for hover text.

Restart the shell after changing QML:

```bash
omarchy restart shell
```
