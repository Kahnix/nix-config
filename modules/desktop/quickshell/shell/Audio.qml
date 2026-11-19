pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
  id: root

  readonly property PwNode sink: Pipewire.defaultAudioSink
  readonly property PwNode source: Pipewire.defaultAudioSource
  readonly property real volume: sink?.audio?.volume ?? 0
  readonly property bool muted: sink?.audio?.muted ?? true
  readonly property real micVolume: source?.audio?.volume ?? 0
  readonly property bool micMuted: source?.audio?.muted ?? true
  readonly property string sinkName: sink?.description || sink?.nickname || sink?.name || "Output"
  readonly property string sourceName: source?.description || source?.nickname || source?.name || "Microphone"

  // Node properties only update for tracked objects.
  PwObjectTracker {
    objects: [root.sink, root.source].filter(n => n)
  }

  function setVolume(node, value) {
    if (!node?.audio) return;
    node.audio.muted = false;
    node.audio.volume = Math.max(0, Math.min(1, value));
  }

  function toggleMute(node) {
    if (node?.audio) node.audio.muted = !node.audio.muted;
  }

  function icon(value, isMuted) {
    if (isMuted || value <= 0) return Theme.iVolOff;
    if (value < 0.34) return Theme.iVolLow;
    if (value < 0.67) return Theme.iVolMid;
    return Theme.iVolHigh;
  }
}
