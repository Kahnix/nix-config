pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
  // The playing player wins; otherwise the first one with a track loaded.
  readonly property MprisPlayer player: {
    const players = Mpris.players.values;
    return Ui.find(players, p => p.isPlaying)
      ?? Ui.find(players, p => (p.trackTitle ?? "") !== "")
      ?? null;
  }
  readonly property string title: player?.trackTitle ?? ""
  readonly property string artist: player?.trackArtist ?? ""
  readonly property string label: artist ? artist + " — " + title : title
}
