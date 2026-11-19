pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Tailscale status and peer list from `tailscale status --json`, polled every
// 15s and on demand from the control center.
Singleton {
  id: root

  property bool available: false
  property bool connected: false
  property string state: ""
  property string selfName: ""
  property string selfIp: ""
  property string tailnet: ""
  property string exitNode: ""
  property var peers: []
  property bool busy: false

  function refresh() {
    if (!statusProc.running) statusProc.running = true;
  }

  function toggle() {
    if (busy) return;
    busy = true;
    actionProc.command = connected ? ["tailscale", "down"] : ["tailscale", "up"];
    actionProc.running = true;
  }

  function setExitNode(ip) {
    if (busy) return;
    busy = true;
    actionProc.command = ["tailscale", "set", "--exit-node=" + (ip || "")];
    actionProc.running = true;
  }

  function copyIp(ip) {
    if (!ip) return;
    Quickshell.execDetached(["sh", "-c", 'printf "%s" "$1" | wl-copy', "sh", ip]);
    Quickshell.execDetached(["notify-send", "-a", "Tailscale", "Copied IP", ip]);
  }

  Process {
    id: statusProc
    command: ["tailscale", "status", "--json"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const data = JSON.parse(text);
          root.available = true;
          root.state = data.BackendState ?? "";
          root.connected = root.state === "Running";
          root.selfName = data.Self?.HostName ?? "";
          const ips = data.TailscaleIPs ?? [];
          root.selfIp = ips.length > 0 ? ips[0] : "";
          root.tailnet = data.CurrentTailnet?.Name ?? data.MagicDNSSuffix ?? "";

          const peerMap = data.Peer ?? {};
          const list = [];
          let activeExit = "";
          for (const k in peerMap) {
            const p = peerMap[k];
            const pIps = p.TailscaleIPs ?? [];
            const ip = pIps.length > 0 ? pIps[0] : "";
            if (p.ExitNode) activeExit = p.HostName ?? ip;
            list.push({
              name: p.HostName ?? k,
              ip: ip,
              os: p.OS ?? "",
              online: Boolean(p.Online),
              exitNode: Boolean(p.ExitNode),
              exitNodeOption: Boolean(p.ExitNodeOption)
            });
          }
          list.sort((a, b) => (b.online - a.online) || a.name.localeCompare(b.name));
          root.exitNode = activeExit;
          root.peers = list;
        } catch (e) {
          root.available = false;
          root.connected = false;
        }
      }
    }
  }

  Process {
    id: actionProc
    onExited: {
      root.busy = false;
      retryTimer.restart();
    }
  }

  Timer {
    id: retryTimer
    interval: 600
    repeat: false
    onTriggered: root.refresh()
  }

  Timer {
    interval: 15000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }
}
