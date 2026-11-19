pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// CPU and memory from /proc, GPU load and temperature from nvidia-smi,
// sampled every three seconds. Percentages are 0..100; -1 means unknown.
Singleton {
  id: root

  property int cpu: 0
  property int mem: 0
  property int gpu: -1
  property int gpuTemp: -1

  property var lastCpu: null

  FileView {
    id: stat
    path: "/proc/stat"
    onLoaded: {
      const f = text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
      const idle = f[3] + f[4];
      const total = f.reduce((a, b) => a + b, 0);
      if (root.lastCpu && total > root.lastCpu.total)
        root.cpu = Math.round(100 * (1 - (idle - root.lastCpu.idle) / (total - root.lastCpu.total)));
      root.lastCpu = { idle: idle, total: total };
    }
  }

  FileView {
    id: meminfo
    path: "/proc/meminfo"
    onLoaded: {
      const total = Number(text().match(/MemTotal:\s+(\d+)/)?.[1] ?? 0);
      const avail = Number(text().match(/MemAvailable:\s+(\d+)/)?.[1] ?? 0);
      if (total > 0) root.mem = Math.round(100 * (1 - avail / total));
    }
  }

  Process {
    id: nvidia
    command: ["nvidia-smi", "--query-gpu=utilization.gpu,temperature.gpu", "--format=csv,noheader,nounits"]
    stdout: StdioCollector {
      onStreamFinished: {
        const [util, temp] = text.split("\n")[0].split(",").map(s => parseInt(s));
        root.gpu = isNaN(util) ? -1 : util;
        root.gpuTemp = isNaN(temp) ? -1 : temp;
      }
    }
  }

  Timer {
    interval: 3000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      stat.reload();
      meminfo.reload();
      if (!nvidia.running) nvidia.running = true;
    }
  }
}
