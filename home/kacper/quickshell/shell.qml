import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
  id: root

  property bool launcherOpen: false
  property bool controlCenterOpen: false

  function toggleLauncher() {
    launcherOpen = !launcherOpen;
    if (launcherOpen) controlCenterOpen = false;
  }

  function toggleControlCenter() {
    controlCenterOpen = !controlCenterOpen;
    if (controlCenterOpen) launcherOpen = false;
  }

  IpcHandler {
    target: "desktop"

    function toggleLauncher(): void { root.toggleLauncher(); }
    function toggleControlCenter(): void { root.toggleControlCenter(); }
    function closeOverlays(): void {
      root.launcherOpen = false;
      root.controlCenterOpen = false;
    }
  }

  Bar { shell: root }
  Launcher { shell: root }

  Notifications {
    id: notifications
    shell: root
  }

  ControlCenter {
    shell: root
    notificationServer: notifications.server
  }
}
