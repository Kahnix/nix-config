pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Live wallpaper picker backed by ~/Pictures/Wallpapers, persisted in
// ~/.local/state/quickshell/.../wallpaper.json. Falls back to Stylix.wallpaper.
Singleton {
  id: root

  readonly property string folder: Quickshell.env("HOME") + "/Pictures/Wallpapers"
  readonly property string active: state.current || Stylix.wallpaper
  readonly property bool isDefault: !state.current
  property var items: []

  FileView {
    id: store
    path: Quickshell.statePath("wallpaper.json")
    onLoadFailed: error => {
      if (error === FileViewError.FileNotFound) writeAdapter();
    }

    JsonAdapter {
      id: state
      property string current: ""
    }
  }

  function refresh() {
    if (!scanner.running) scanner.running = true;
  }

  function select(path) {
    state.current = path;
    store.writeAdapter();
  }

  function reset() {
    state.current = "";
    store.writeAdapter();
  }

  function openFolder() {
    Ui.run(["thunar", root.folder]);
  }

  Process {
    id: scanner
    command: [
      "sh", "-c",
      "mkdir -p \"$1\" && find \"$1\" -maxdepth 2 -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \\) | sort",
      "sh", root.folder
    ]
    stdout: StdioCollector {
      onStreamFinished: {
        const lines = text.trim().split("\n").filter(l => l.length > 0);
        root.items = lines.map(p => ({
          path: p,
          name: p.split("/").pop().replace(/\.[^.]+$/, "")
        }));
      }
    }
  }
}
