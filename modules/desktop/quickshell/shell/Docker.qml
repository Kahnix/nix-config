pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Local Docker containers from `docker ps -a --format '{{json .}}'`, polled
// every 10s and on demand from the control center.
Singleton {
  id: root

  property bool available: false
  property var containers: []
  readonly property int runningCount: containers.filter(c => c.running).length

  function refresh() {
    if (!listProc.running) listProc.running = true;
  }

  function runAction(verb, id) {
    Quickshell.execDetached(["sh", "-c", "docker \"$1\" \"$2\"", "sh", verb, id]);
    refreshTimer.restart();
  }

  function start(id) { runAction("start", id); }
  function stop(id) { runAction("stop", id); }
  function restart(id) { runAction("restart", id); }

  Process {
    id: listProc
    command: ["docker", "ps", "-a", "--format", "{{json .}}"]
    stdout: StdioCollector {
      onStreamFinished: {
        const lines = text.trim().split("\n").filter(l => l.length > 0);
        const list = [];
        for (let i = 0; i < lines.length; i++) {
          try {
            const c = JSON.parse(lines[i]);
            const state = (c.State ?? "").toLowerCase();
            list.push({
              id: c.ID ?? "",
              name: (c.Names ?? "").replace(/^\//, ""),
              image: c.Image ?? "",
              state: state,
              status: c.Status ?? "",
              running: state === "running"
            });
          } catch (e) {}
        }
        list.sort((a, b) => (b.running - a.running) || a.name.localeCompare(b.name));
        root.available = true;
        root.containers = list;
      }
    }
    onExited: code => {
      if (code !== 0) {
        root.available = false;
        root.containers = [];
      }
    }
  }

  Timer {
    id: refreshTimer
    interval: 800
    repeat: false
    onTriggered: root.refresh()
  }

  Timer {
    interval: 10000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }
}
