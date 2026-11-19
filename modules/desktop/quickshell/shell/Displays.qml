pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Connected Hyprland monitors via `hyprctl monitors -j`, with quick live
// scale and mode switching.
Singleton {
  id: root

  property var monitors: []

  function refresh() {
    if (!query.running) query.running = true;
  }

  function apply(spec) {
    Quickshell.execDetached(["hyprctl", "keyword", "monitor", spec]);
    refreshTimer.restart();
  }

  function setScale(mon, scale) {
    const hz = Number(mon.refreshRate || 60).toFixed(2);
    apply(mon.name + "," + mon.width + "x" + mon.height + "@" + hz + "," + mon.x + "x" + mon.y + "," + scale);
  }

  function setMode(mon, modeStr) {
    const clean = modeStr.replace("Hz", "");
    apply(mon.name + "," + clean + "," + mon.x + "x" + mon.y + "," + mon.scale);
  }

  function topModes(mon) {
    const raw = mon.availableModes ?? [];
    const seen = {};
    const out = [];
    for (let i = 0; i < raw.length && out.length < 4; i++) {
      const m = raw[i];
      if (!seen[m]) {
        seen[m] = true;
        out.push(m);
      }
    }
    return out;
  }

  Process {
    id: query
    command: ["hyprctl", "monitors", "-j"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          root.monitors = JSON.parse(text);
        } catch (e) {
          console.warn("displays: parse error", e);
        }
      }
    }
  }

  Timer {
    id: refreshTimer
    interval: 350
    repeat: false
    onTriggered: root.refresh()
  }
}
