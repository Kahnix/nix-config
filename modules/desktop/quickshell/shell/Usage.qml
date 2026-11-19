pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// AI plan quotas from `ai-usagebar usage --json` (modules/home/ai-usage.nix),
// polled every minute (with a 15s retry while a provider is still starting up)
// and on demand from the control center.
Singleton {
  id: root

  property var entries: []
  readonly property bool loading: proc.running
  readonly property var ready: entries.filter(e => (e.status === "ready" || e.stale) && (e.metrics?.length ?? 0) > 0)

  FileView {
    id: cacheFile
    path: Quickshell.statePath("usage-cache.json")
    onLoadFailed: error => {
      if (error === FileViewError.FileNotFound) writeAdapter();
    }

    JsonAdapter {
      id: cache
      property var providers: ({})
    }
  }

  function refresh() {
    if (!proc.running) proc.running = true;
  }

  // Pick the highest-usage 5h session metric if available, else highest overall.
  function primaryMetric(entry) {
    const metrics = entry?.metrics ?? [];
    if (metrics.length === 0) return null;
    const session = metrics.filter(m => m.window_secs === 18000);
    const pool = session.length > 0 ? session : metrics;
    let best = pool[0];
    for (let i = 1; i < pool.length; i++)
      if ((pool[i].percent ?? 0) > (best.percent ?? 0)) best = pool[i];
    return best;
  }

  function windowLabel(metric) {
    const secs = metric?.window_secs ?? 0;
    if (secs <= 0) return "";
    const hours = Math.round(secs / 3600);
    if (hours < 24) return hours + "h";
    return Math.round(hours / 24) + "d";
  }

  Process {
    id: proc
    command: ["ai-usagebar", "usage", "--json"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const parsed = JSON.parse(text).entries ?? [];
          const nextCache = Object.assign({}, cache.providers);
          let cacheDirty = false;
          const merged = parsed.map(entry => {
            const key = entry.provider ?? entry.display_name;
            if (entry.status === "ready" && (entry.metrics?.length ?? 0) > 0) {
              nextCache[key] = Object.assign({}, entry, { cached_at: Date.now() });
              cacheDirty = true;
              return Object.assign({}, entry, { stale: false });
            }
            const prev = nextCache[key];
            if (prev && (prev.metrics?.length ?? 0) > 0) {
              return Object.assign({}, prev, {
                stale: true,
                error: entry.error ?? entry.status
              });
            }
            return Object.assign({}, entry, { stale: false });
          });
          if (cacheDirty) {
            cache.providers = nextCache;
            cacheFile.writeAdapter();
          }
          root.entries = merged;
          if (parsed.some(e => e.status !== "ready")) retryTimer.restart();
        } catch (e) {
          console.warn("ai-usagebar: unreadable output", e);
        }
      }
    }
    stderr: StdioCollector {
      onStreamFinished: {
        if (text.trim().length > 0) console.warn("ai-usagebar:", text.trim());
      }
    }
  }

  Timer {
    id: retryTimer
    interval: 15 * 1000
    repeat: false
    onTriggered: root.refresh()
  }

  Timer {
    interval: 60 * 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }
}
