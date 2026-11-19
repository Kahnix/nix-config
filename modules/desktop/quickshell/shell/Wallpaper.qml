import QtQuick
import Quickshell
import Quickshell.Wayland

// Wallpaper on the background layer of every monitor.
Variants {
  model: Quickshell.screens

  PanelWindow {
    required property ShellScreen modelData

    screen: modelData
    color: Theme.bg
    WlrLayershell.namespace: "qs-wallpaper"
    WlrLayershell.layer: WlrLayer.Background
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }

    Image {
      anchors.fill: parent
      source: "file://" + Wallpapers.active
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      sourceSize.width: width
      sourceSize.height: height
    }
  }
}
