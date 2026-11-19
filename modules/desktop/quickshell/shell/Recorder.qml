pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Screen recording of the focused monitor with gpu-screen-recorder (NVENC
// h264, desktop audio) into ~/Videos/Recordings. SIGINT finalises the file.
Singleton {
  id: root

  readonly property bool active: proc.running
  property string file: ""
  property real startedAt: 0
  property int elapsed: 0

  function toggle() {
    if (proc.running) {
      proc.signal(2);
      return;
    }
    const stamp = Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss");
    file = Quickshell.env("HOME") + "/Videos/Recordings/" + stamp + ".mp4";
    const monitor = Hyprland.focusedMonitor?.name ?? "screen";
    proc.command = ["sh", "-c",
      'mkdir -p "$(dirname "$1")" && exec gpu-screen-recorder -w "$2" -f 60 -k h264 -a default_output -o "$1"',
      "sh", file, monitor];
    startedAt = Date.now();
    elapsed = 0;
    proc.running = true;
  }

  Process {
    id: proc
    onExited: (code, status) => {
      if (code === 0)
        Quickshell.execDetached(["notify-send", "-a", "Screen recorder", "-i", "video-x-generic",
          "Recording saved", root.file.replace(Quickshell.env("HOME"), "~")]);
      else
        Quickshell.execDetached(["notify-send", "-a", "Screen recorder", "-u", "critical",
          "Recording failed", "gpu-screen-recorder exited with code " + code]);
    }
  }

  Timer {
    interval: 1000
    running: root.active
    repeat: true
    onTriggered: root.elapsed = Math.floor((Date.now() - root.startedAt) / 1000)
  }

  function clock(seconds) {
    const m = Math.floor(seconds / 60);
    const s = seconds % 60;
    return m + ":" + (s < 10 ? "0" : "") + s;
  }
}
