pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Audio spectrum from cava (config generated in quickshell.nix), 0..1 per
// bar. Runs only while a player is playing, so it costs nothing otherwise.
Singleton {
  id: root

  readonly property bool active: Media.player?.isPlaying ?? false
  property var bars: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

  onActiveChanged: if (!active) bars = bars.map(() => 0)

  Process {
    command: Stylix.cava
    running: root.active
    stdout: SplitParser {
      onRead: line => {
        const values = line.split(";");
        const next = [];
        for (let i = 0; i < values.length; i++)
          if (values[i] !== "") next.push(Math.min(1, Number(values[i]) / 100));
        if (next.length > 0) root.bars = next;
      }
    }
  }
}
