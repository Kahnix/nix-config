pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Active network connection from NetworkManager (`nmcli`).
Singleton {
  id: root

  property bool connected: false
  property string type: "none" // "wifi" | "ethernet" | "none"
  property string name: ""
  property int signal: -1

  function refresh() {
    if (!devProc.running) devProc.running = true;
  }

  function icon() {
    if (!connected) return Theme.iWifiOff;
    return type === "ethernet" ? Theme.iEthernet : Theme.iWifi;
  }

  Process {
    id: devProc
    command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION", "device"]
    stdout: StdioCollector {
      onStreamFinished: {
        let foundType = "none";
        let foundName = "";
        const lines = text.trim().split("\n");
        for (let i = 0; i < lines.length; i++) {
          const parts = lines[i].split(":");
          if (parts.length < 3) continue;
          const [t, state, conn] = parts;
          if (state === "connected" && (t === "ethernet" || t === "wifi")) {
            foundType = t;
            foundName = conn;
            if (t === "ethernet") break;
          }
        }
        root.connected = foundType !== "none";
        root.type = foundType;
        root.name = foundName;
        if (foundType === "wifi" && !wifiProc.running) wifiProc.running = true;
        else if (foundType !== "wifi") root.signal = -1;
      }
    }
  }

  Process {
    id: wifiProc
    command: ["nmcli", "-t", "-f", "IN-USE,SIGNAL", "device", "wifi", "list", "--rescan", "no"]
    stdout: StdioCollector {
      onStreamFinished: {
        const lines = text.trim().split("\n");
        for (let i = 0; i < lines.length; i++) {
          if (lines[i].startsWith("*:")) {
            const sig = parseInt(lines[i].split(":")[1]);
            root.signal = isNaN(sig) ? -1 : sig;
            return;
          }
        }
        root.signal = -1;
      }
    }
  }

  Timer {
    interval: 10000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }
}
