//@ pragma UseQApplication
//@ pragma IconTheme Papirus-Dark

import QtQuick
import Quickshell
import Quickshell.Io

// Desktop shell. Panels are toggled from Hyprland binds (binds.lua) with
// `qs ipc call shell <function>`.
ShellRoot {
  Wallpaper {}
  Bar {}
  Toasts {}
  Osd {}
  CalendarPopup {}
  ControlCenter {}
  Launcher {}
  SessionMenu {}

  IpcHandler {
    target: "shell"

    function launcher(): void { Ui.toggleLauncher("apps"); }
    function clipboard(): void { Ui.toggleLauncher("clipboard"); }
    function controlCenter(): void { Ui.toggleControl(); }
    function session(): void { Ui.toggleSession(); }
    function dnd(): void { Notifs.dnd = !Notifs.dnd; }
  }
}
