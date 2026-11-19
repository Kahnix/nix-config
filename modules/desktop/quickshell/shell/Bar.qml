import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import Quickshell.Widgets

// Top bar, one per monitor: floating islands over a transparent strip.
//   left:   launcher + workspaces, then the focused window
//   centre: clock
//   right:  now playing (art + visualizer), system load, status
Variants {
  model: Quickshell.screens

  PanelWindow {
    id: win

    required property ShellScreen modelData
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(modelData)
    // Narrow modes (Sunshine streams at 1680x1050) drop the window title,
    // track name and load readout so the islands never collide.
    readonly property bool compact: modelData.width < 2400

    screen: modelData
    color: "transparent"
    WlrLayershell.namespace: "qs-bar"
    WlrLayershell.layer: WlrLayer.Top
    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.barHeight + Theme.gap
    // Hyprland adds gaps_out below this, so windows sit one gap under the bar.
    exclusiveZone: Theme.barHeight + Theme.gap - Theme.edge + Theme.gap

    // Keeps the session awake while toggled from the control center.
    IdleInhibitor {
      window: win
      enabled: Ui.keepAwake
    }

    component Divider: Rectangle {
      Layout.leftMargin: 4
      Layout.rightMargin: 4
      implicitWidth: 1
      implicitHeight: 16
      color: Theme.alpha(Theme.text, 0.1)
    }

    Item {
      anchors.fill: parent
      anchors.topMargin: Theme.gap
      anchors.leftMargin: Theme.edge
      anchors.rightMargin: Theme.edge

      // ── Left ──────────────────────────────────────────────
      RowLayout {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Island {
          BarButton {
            active: Ui.launcherOpen
            padding: 8
            onClicked: Ui.toggleLauncher("apps")
            Item {
              implicitWidth: 18
              implicitHeight: 18
              Image {
                anchors.centerIn: parent
                width: 18
                height: 18
                source: Stylix.nixIcon
                smooth: true
                mipmap: true
              }
            }
          }
          Divider {}
          Workspaces { monitor: win.monitor }
        }

        Island {
          visible: !win.compact && ToplevelManager.activeToplevel !== null
          padding: 10

          RowLayout {
            spacing: 8

            IconImage {
              Layout.alignment: Qt.AlignVCenter
              implicitSize: 16
              source: {
                const id = ToplevelManager.activeToplevel?.appId ?? "";
                const entry = id ? DesktopEntries.heuristicLookup(id) : null;
                return id ? Quickshell.iconPath(entry?.icon ?? id, "application-x-executable") : "";
              }
            }
            Label {
              Layout.alignment: Qt.AlignVCenter
              Layout.maximumWidth: 340
              text: ToplevelManager.activeToplevel?.title ?? ""
              color: Theme.text
              size: 12
            }
          }
        }
      }

      // ── Centre ────────────────────────────────────────────
      Island {
        anchors.centerIn: parent
        tint: Ui.calendarOpen ? Theme.alpha(Theme.accent, 0.14) : "transparent"

        SystemClock { id: clock; precision: SystemClock.Minutes }

        BarButton {
          padding: 12
          onClicked: Ui.toggleCalendar()

          Label {
            monospace: true
            size: 14
            text: Qt.formatDateTime(clock.date, "HH:mm")
            font.weight: Font.Bold
            color: Theme.bright
          }
          Rectangle {
            width: 4; height: 4; radius: 2
            color: Theme.accent
          }
          Label {
            monospace: true
            size: 12
            text: Qt.formatDateTime(clock.date, "ddd dd MMM").toLowerCase()
            color: Theme.muted
          }
          Rectangle {
            visible: Weather.ready
            width: 1; height: 12
            color: Theme.alpha(Theme.text, 0.12)
          }
          Row {
            visible: Weather.ready
            spacing: 4
            Glyph {
              anchors.verticalCenter: parent.verticalCenter
              glyph: Weather.glyphFor(Weather.code, Weather.isDay)
              size: 14
              color: Theme.accentAlt
            }
            Label {
              anchors.verticalCenter: parent.verticalCenter
              monospace: true
              size: 12
              text: Weather.temp + "°"
              color: Theme.text
            }
          }
        }
      }

      // ── Right ─────────────────────────────────────────────
      RowLayout {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        // Now playing: compact icon + title only.
        Island {
          visible: Media.player !== null && Media.title !== ""
          padding: 3

          BarButton {
            padding: 8
            onClicked: button => {
              if (button === Qt.MiddleButton) Media.player.next();
              else if (button === Qt.RightButton) Ui.toggleControl();
              else Media.player.togglePlaying();
            }
            onScrolled: delta => delta > 0 ? Media.player.previous() : Media.player.next()

            Glyph {
              glyph: Media.player?.isPlaying ? Theme.iMusic : Theme.iPause
              size: 13
              color: Media.player?.isPlaying ? Theme.accent : Theme.muted
            }

            Label {
              visible: !win.compact
              Layout.maximumWidth: 160
              text: Media.title
              size: 12
              color: Media.player?.isPlaying ? Theme.text : Theme.muted
            }
          }
        }

        // System load; click for Mission Center.
        Island {
          visible: !win.compact
          BarButton {
            padding: 10
            onClicked: Ui.run(["missioncenter"])

            Repeater {
              model: [
                { icon: Theme.iCpu, value: Stats.cpu, suffix: "%" },
                { icon: Theme.iMem, value: Stats.mem, suffix: "%" },
                { icon: Theme.iGpu, value: Stats.gpu, suffix: Stats.gpuTemp >= 0 ? "% " + Stats.gpuTemp + "°" : "%" }
              ]

              Row {
                required property var modelData
                visible: modelData.value >= 0
                spacing: 4

                Glyph {
                  anchors.verticalCenter: parent.verticalCenter
                  glyph: modelData.icon
                  size: 13
                  color: Theme.muted
                }
                Label {
                  anchors.verticalCenter: parent.verticalCenter
                  monospace: true
                  size: 12
                  text: modelData.value + modelData.suffix
                  color: modelData.value >= 85 ? Theme.danger : modelData.value >= 60 ? Theme.warn : Theme.text
                }
              }
            }
          }
        }

        // Status: quotas, tray, volume, notifications, power.
        Island {
          BarButton {
            visible: Recorder.active
            onClicked: Recorder.toggle()

            Rectangle {
              width: 8; height: 8; radius: 4
              color: Theme.danger
              SequentialAnimation on opacity {
                running: Recorder.active
                loops: Animation.Infinite
                NumberAnimation { to: 0.3; duration: 700 }
                NumberAnimation { to: 1; duration: 700 }
              }
            }
            Label { monospace: true; text: Recorder.clock(Recorder.elapsed); size: 12; color: Theme.danger }
          }

          BarButton {
            visible: Ui.keepAwake
            onClicked: Ui.keepAwake = false
            Glyph { glyph: Theme.iCoffee; color: Theme.warn; size: 15 }
          }

          // Tailscale status; click opens Services tab.
          BarButton {
            visible: Tailscale.available
            onClicked: Ui.openControlTab("services")
            Glyph {
              glyph: Theme.iVpn
              size: 15
              color: Tailscale.connected ? Theme.good : Theme.faint
            }
          }

          // Docker running containers; click opens Services tab.
          BarButton {
            visible: Docker.available && Docker.runningCount > 0
            onClicked: Ui.openControlTab("services")
            Glyph { glyph: Theme.iDocker; size: 15; color: Theme.accent }
            Label {
              monospace: true
              size: 11
              text: Docker.runningCount
              color: Theme.muted
            }
          }

          // AI plan quotas: one ring per provider, coloured by its highest active window.
          BarButton {
            visible: Usage.ready.length > 0
            onClicked: Ui.openControlTab("ai")

            Repeater {
              model: Usage.ready

              Row {
                required property var modelData
                readonly property var metric: Usage.primaryMetric(modelData)
                spacing: 5

                Ring {
                  anchors.verticalCenter: parent.verticalCenter
                  value: (metric?.percent ?? 0) / 100
                  fill: Theme.level(metric?.percent ?? 0)
                }
                Label {
                  anchors.verticalCenter: parent.verticalCenter
                  monospace: true
                  size: 11
                  text: modelData.short_name
                  color: Theme.muted
                }
              }
            }
          }

          Divider { visible: SystemTray.items.values.length > 0 }

          Repeater {
            model: SystemTray.items

            BarButton {
              id: trayButton
              required property SystemTrayItem modelData
              padding: 6
              onClicked: button => {
                if (button === Qt.RightButton || modelData.onlyMenu) {
                  const p = trayButton.mapToItem(null, 0, trayButton.height + 10);
                  modelData.display(win, p.x, p.y);
                } else if (button === Qt.MiddleButton) {
                  modelData.secondaryActivate();
                } else {
                  modelData.activate();
                }
              }
              onScrolled: delta => modelData.scroll(delta, false)

              IconImage {
                implicitSize: 16
                source: trayButton.modelData.icon
              }
            }
          }

          Divider {}

          BarButton {
            active: Ui.launcherOpen && Ui.launcherMode === "clipboard"
            padding: 7
            onClicked: Ui.toggleLauncher("clipboard")
            Glyph { glyph: Theme.iClipboard; size: 15; color: Theme.muted }
          }

          BarButton {
            padding: 7
            onClicked: button => button === Qt.RightButton ? Ui.run(["nm-connection-editor"]) : Ui.toggleControl()
            Glyph {
              glyph: Network.icon()
              size: 15
              color: Network.connected ? Theme.text : Theme.faint
            }
          }

          BarButton {
            onClicked: button => button === Qt.RightButton ? Ui.run(["pavucontrol"]) : Audio.toggleMute(Audio.sink)
            onScrolled: delta => Audio.setVolume(Audio.sink, Audio.volume + (delta > 0 ? 0.05 : -0.05))

            Glyph {
              glyph: Audio.icon(Audio.volume, Audio.muted)
              color: Audio.muted ? Theme.faint : Theme.text
            }
            Label {
              monospace: true
              size: 12
              text: Math.round(Audio.volume * 100)
              color: Audio.muted ? Theme.faint : Theme.text
            }
          }

          BarButton {
            active: Ui.controlOpen
            onClicked: Ui.toggleControl()

            Glyph {
              glyph: Notifs.dnd ? Theme.iBellOff : Theme.iBell
              color: Notifs.dnd ? Theme.faint : Notifs.count > 0 ? Theme.text : Theme.muted
            }
            Rectangle {
              visible: Notifs.count > 0
              width: Math.max(16, countLabel.implicitWidth + 8)
              height: 16
              radius: 8
              color: Theme.accent
              Label {
                id: countLabel
                anchors.centerIn: parent
                monospace: true
                size: 10
                font.weight: Font.Bold
                text: Notifs.count
                color: Theme.bg
              }
            }
          }

          BarButton {
            active: Ui.sessionOpen
            onClicked: Ui.toggleSession()
            Glyph { glyph: Theme.iPower; color: Theme.danger; size: 15 }
          }
        }
      }
    }
  }
}
