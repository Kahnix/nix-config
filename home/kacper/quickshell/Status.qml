pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Scope {
  id: root

  property string networkName: "offline"
  property string networkKind: "none"
  property int cpuUsage: 0
  property int memoryUsage: 0

  function refresh() {
    if (!networkProcess.running) networkProcess.running = true;
    if (!statsProcess.running) statsProcess.running = true;
  }

  Process {
    id: networkProcess
    command: [
      "sh",
      "-c",
      "wifi=$(nmcli -t -f TYPE,STATE,CONNECTION device status | sed -n 's/^wifi:connected://p' | head -n1); if [ -n \"$wifi\" ]; then printf 'wifi\\t%s\\n' \"$wifi\"; else wired=$(nmcli -t -f TYPE,STATE,CONNECTION device status | sed -n 's/^ethernet:connected://p' | head -n1); if [ -n \"$wired\" ]; then printf 'wired\\t%s\\n' \"$wired\"; else printf 'none\\toffline\\n'; fi; fi"
    ]
    stdout: StdioCollector {
      onStreamFinished: {
        const fields = this.text.trim().split("\t");
        root.networkKind = fields[0] || "none";
        root.networkName = fields[1] || "offline";
      }
    }
  }

  Process {
    id: statsProcess
    command: [
      "sh",
      "-c",
      "cpu=$(LC_ALL=C top -bn1 | awk '/Cpu\\(s\\)/ { print int(100-$8); exit }'); mem=$(free | awk '/Mem:/ { print int($3*100/$2) }'); printf '%s\\t%s\\n' \"${cpu:-0}\" \"${mem:-0}\""
    ]
    stdout: StdioCollector {
      onStreamFinished: {
        const fields = this.text.trim().split("\t");
        root.cpuUsage = Number(fields[0]) || 0;
        root.memoryUsage = Number(fields[1]) || 0;
      }
    }
  }

  Timer {
    interval: 2500
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }
}
