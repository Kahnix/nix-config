pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// cliphist history (services.cliphist stores it). Each entry is the raw
// `<id>\t<preview>` line, which is what `cliphist decode/delete` read on stdin.
Singleton {
  id: root

  property var items: []

  function refresh() {
    lister.running = true;
  }

  function preview(item) {
    const m = item.text.match(/^\[\[ binary data (.*) \]\]$/);
    return m ? "Image · " + m[1] : item.text;
  }

  function copy(item) {
    Quickshell.execDetached(["sh", "-c", 'printf "%s" "$1" | cliphist decode | wl-copy', "sh", item.line]);
  }

  function remove(item) {
    Quickshell.execDetached(["sh", "-c", 'printf "%s" "$1" | cliphist delete', "sh", item.line]);
    items = items.filter(i => i !== item);
  }

  function wipe() {
    Quickshell.execDetached(["cliphist", "wipe"]);
    items = [];
  }

  Process {
    id: lister
    command: ["cliphist", "list"]
    stdout: StdioCollector {
      onStreamFinished: {
        root.items = text.split("\n").filter(l => l.length > 0).map(line => {
          const tab = line.indexOf("\t");
          return { line: line, text: line.slice(tab + 1).trim() };
        });
      }
    }
  }
}
