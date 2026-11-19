pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Desktop-entry search, ranked by match quality and then by how often each
// app was launched from here (kept in ~/.local/state/quickshell/.../launches.json).
Singleton {
  id: root

  FileView {
    id: store
    path: Quickshell.statePath("launches.json")
    onLoadFailed: error => {
      if (error === FileViewError.FileNotFound) writeAdapter();
    }

    JsonAdapter {
      id: launches
      property var counts: ({})
    }
  }

  function uses(entry) {
    return launches.counts[entry.id] ?? 0;
  }

  function score(entry, q) {
    const name = entry.name.toLowerCase();
    if (name.startsWith(q)) return 4;
    if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q))) return 3;
    if (name.includes(q)) return 2;
    const rest = [entry.genericName, entry.comment, (entry.keywords ?? []).join(" "), entry.id]
      .join(" ").toLowerCase();
    return rest.includes(q) ? 1 : 0;
  }

  function search(query, limit) {
    const q = query.trim().toLowerCase();
    const apps = Array.from(DesktopEntries.applications.values).filter(e => !e.noDisplay);
    const ranked = [];
    for (const entry of apps) {
      const s = q ? score(entry, q) : 1;
      if (s > 0) ranked.push({ entry: entry, score: s, uses: uses(entry) });
    }
    ranked.sort((a, b) => b.score - a.score || b.uses - a.uses
      || a.entry.name.localeCompare(b.entry.name));
    return ranked.slice(0, limit).map(r => r.entry);
  }

  function launch(entry) {
    const counts = Object.assign({}, launches.counts);
    counts[entry.id] = (counts[entry.id] ?? 0) + 1;
    launches.counts = counts;
    store.writeAdapter();
    // uwsm resolves the desktop entry itself, Terminal=true included.
    Ui.run([entry.id + ".desktop"]);
  }
}
