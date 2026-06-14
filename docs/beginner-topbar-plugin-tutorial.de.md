# Einsteigeranleitung: Ein kleines Omarchy-Topbar-Plugin bauen

Status: reference

Diese Anleitung baut das kleinstmoegliche nuetzliche Omarchy-Topbar-Plugin:
ein Widget, das `hello` in der Leiste anzeigt. Keine CPU-Statistiken, keine
Skripte, keine Assets und kein Lacuna-Styling.

## 1. Plugin-Ordner erstellen

Benutzer-Plugins liegen hier:

```text
~/.config/omarchy/plugins/
```

Erstelle einen neuen Plugin-Ordner:

```bash
mkdir -p ~/.config/omarchy/plugins/omarchy.example-hello
cd ~/.config/omarchy/plugins/omarchy.example-hello
```

Dein Plugin besteht aus zwei Dateien:

```text
omarchy.example-hello/
  manifest.json
  Widget.qml
```

## 2. `manifest.json` erstellen

Erstelle diese Datei:

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

Wichtig sind diese Felder:

- `id` ist der Name, den du spaeter in `shell.json` eintraegst.
- `kinds` sagt Omarchy, dass dies ein Topbar-Widget ist.
- `entryPoints.barWidget` zeigt auf die QML-Datei, die geladen wird.

## 3. `Widget.qml` erstellen

Erstelle diese Datei:

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

Omarchy fuellt diese Properties automatisch:

- `bar`: Zugriff auf Farben, Schrift, Groesse, Hilfsfunktionen und Position.
- `moduleName`: die Widget-ID.
- `settings`: Optionen aus dem Eintrag des Widgets in `shell.json`.

`implicitWidth` und `implicitHeight` sagen der Leiste, wie viel Platz das Widget
braucht.

## 4. Omarchy das Plugin finden lassen

Lass die laufende Shell nach Plugins suchen:

```bash
omarchy plugin rescan
```

Wenn das Widget spaeter nicht erscheint, starte die Shell neu:

```bash
omarchy restart shell
```

## 5. Zur Topbar hinzufuegen

Oeffne:

```text
~/.config/omarchy/shell.json
```

Suche `bar.layout`. Fuege dieses Objekt zu `left`, `center` oder `right` hinzu:

```json
{ "id": "omarchy.example-hello" }
```

Beispiel fuer die rechte Seite:

```json
"right": [
  { "id": "Tray" },
  { "id": "omarchy.example-hello" }
]
```

Speichere die Datei. Omarchy laedt `shell.json` normalerweise automatisch neu.
Wenn nicht, fuehre aus:

```bash
omarchy restart shell
```

Jetzt solltest du `hello` in der Topbar sehen.

## 6. Optional: Tooltip hinzufuegen

Wenn das einfache Widget funktioniert, ersetze `Widget.qml` durch diese leicht
verbesserte Version:

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

Das ist das naechste haeufige Muster: `MouseArea` fuer Interaktion und Omarchys
gemeinsame Tooltip-Helfer fuer Hover-Text.

Starte die Shell nach QML-Aenderungen neu:

```bash
omarchy restart shell
```
