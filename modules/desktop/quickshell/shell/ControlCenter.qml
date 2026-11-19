import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

// Bento-island control center anchored under the bar's right side.
// Notifications stay pinned in their own left island; the right side is a
// tabbed cluster of floating islands (Overview, Services, Displays, Wallpaper, AI).
PanelWindow {
  id: win

  readonly property string tab: Ui.controlTab

  screen: Ui.activeScreen
  visible: Ui.controlOpen || root.opacity > 0
  color: "transparent"
  WlrLayershell.namespace: "qs-panel"
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.keyboardFocus: Ui.controlOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore
  anchors { top: true; right: true }
  margins.top: Theme.barHeight + Theme.gap * 2
  margins.right: Theme.edge
  implicitWidth: 856
  implicitHeight: Math.min(548, (screen?.height ?? 1050) - margins.top - Theme.edge)

  HyprlandFocusGrab {
    windows: [win]
    active: Ui.controlOpen
    onCleared: Ui.closeControl()
  }

  onVisibleChanged: {
    if (visible) {
      Usage.refresh();
      Network.refresh();
      Displays.refresh();
      Wallpapers.refresh();
      Tailscale.refresh();
      Docker.refresh();
    }
  }

  FileView {
    id: uptimeFile
    path: "/proc/uptime"
  }
  FileView {
    id: hostFile
    path: "/etc/hostname"
  }
  Timer {
    running: win.visible
    interval: 60000
    repeat: true
    triggeredOnStart: true
    onTriggered: uptimeFile.reload()
  }
  readonly property string uptime: {
    const s = Math.floor(parseFloat(uptimeFile.text()) || 0);
    const d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60);
    return "up " + (d > 0 ? d + "d " : "") + (h > 0 ? h + "h " : "") + m + "m";
  }

  Item {
    id: root
    anchors.fill: parent
    opacity: Ui.controlOpen ? 1 : 0
    transform: Translate {
      y: Ui.controlOpen ? 0 : -12
      Behavior on y { NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic } }
    }
    Behavior on opacity { NumberAnimation { duration: Theme.anim } }

    focus: true
    Keys.onEscapePressed: Ui.closeControl()
    Keys.onPressed: event => {
      if (event.key === Qt.Key_1) Ui.controlTab = "overview";
      else if (event.key === Qt.Key_2) { Ui.controlTab = "services"; Tailscale.refresh(); Docker.refresh(); }
      else if (event.key === Qt.Key_3) { Ui.controlTab = "displays"; Displays.refresh(); }
      else if (event.key === Qt.Key_4) { Ui.controlTab = "wallpaper"; Wallpapers.refresh(); }
      else if (event.key === Qt.Key_5) { Ui.controlTab = "ai"; Usage.refresh(); }
    }

    RowLayout {
      anchors.fill: parent
      spacing: 10

      // ─────────────────────────────────────────────────────────────────────
      // LEFT ISLAND: Dedicated Notifications Feed (always visible, never buried)
      // ─────────────────────────────────────────────────────────────────────
      BentoCard {
        Layout.preferredWidth: 300
        Layout.fillHeight: true

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: 14
          spacing: 10

          RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
              implicitWidth: 28
              implicitHeight: 28
              radius: 8
              color: Notifs.dnd ? Theme.alpha(Theme.warn, 0.18) : Theme.alpha(Theme.accent, 0.16)
              Glyph {
                anchors.centerIn: parent
                glyph: Notifs.dnd ? Theme.iBellOff : Theme.iBell
                size: 14
                color: Notifs.dnd ? Theme.warn : Theme.accent
              }
            }

            Label {
              text: "Notifications"
              font.weight: Font.DemiBold
            }

            Rectangle {
              visible: Notifs.count > 0
              implicitWidth: countLbl.implicitWidth + 10
              implicitHeight: 18
              radius: 9
              color: Theme.alpha(Theme.accent, 0.2)
              Label {
                id: countLbl
                anchors.centerIn: parent
                text: Notifs.count
                monospace: true
                size: 10
                font.weight: Font.Bold
                color: Theme.accent
              }
            }

            Item { Layout.fillWidth: true }

            // DND toggle pill.
            Rectangle {
              implicitWidth: dndRow.implicitWidth + 12
              implicitHeight: 26
              radius: 8
              color: Notifs.dnd
                ? Theme.alpha(Theme.warn, 0.22)
                : dndMouse.containsMouse ? Theme.hover : Theme.card
              border.width: 1
              border.color: Notifs.dnd ? Theme.alpha(Theme.warn, 0.4) : Theme.cardBorder

              RowLayout {
                id: dndRow
                anchors.centerIn: parent
                spacing: 4
                Label {
                  text: "DND"
                  monospace: true
                  size: 10
                  font.weight: Font.DemiBold
                  color: Notifs.dnd ? Theme.warn : Theme.muted
                }
              }
              MouseArea {
                id: dndMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Notifs.dnd = !Notifs.dnd
              }
            }

            IconButton {
              visible: Notifs.count > 0
              size: 26
              glyph: Theme.iTrash
              tint: Theme.muted
              onClicked: Notifs.clear()
            }
          }

          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Theme.cardBorder
          }

          // Empty state.
          Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: Notifs.count === 0

            ColumnLayout {
              anchors.centerIn: parent
              spacing: 10

              Rectangle {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 64
                implicitHeight: 64
                radius: 32
                color: Theme.alpha(Notifs.dnd ? Theme.warn : Theme.accent, 0.08)
                border.width: 1
                border.color: Theme.alpha(Notifs.dnd ? Theme.warn : Theme.accent, 0.2)

                Rectangle {
                  anchors.centerIn: parent
                  width: 44
                  height: 44
                  radius: 22
                  color: Theme.alpha(Notifs.dnd ? Theme.warn : Theme.accent, 0.14)
                  Glyph {
                    anchors.centerIn: parent
                    glyph: Notifs.dnd ? Theme.iBellOff : Theme.iBell
                    size: 20
                    color: Notifs.dnd ? Theme.warn : Theme.accent
                  }
                }
              }

              Label {
                Layout.alignment: Qt.AlignHCenter
                text: Notifs.dnd ? "Do not disturb" : "All quiet"
                font.weight: Font.DemiBold
                color: Theme.text
              }
              Label {
                Layout.alignment: Qt.AlignHCenter
                text: Notifs.dnd ? "Only critical alerts come through" : "No unread notifications"
                size: Theme.fontSmall
                color: Theme.faint
              }
            }
          }

          // Scrollable notification stack.
          Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: Notifs.count > 0
            contentHeight: notifCol.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
              id: notifCol
              width: parent.width
              spacing: 8

              Repeater {
                model: Notifs.list

                NotificationCard {
                  required property var modelData
                  Layout.fillWidth: true
                  notification: modelData
                }
              }
            }
          }
        }
      }

      // ─────────────────────────────────────────────────────────────────────
      // RIGHT SIDE: Header Island + Tabbed Bento Grid
      // ─────────────────────────────────────────────────────────────────────
      ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 10

        // TOP ISLAND: Identity, Weather chip, Power, and Mode Tabs.
        BentoCard {
          Layout.fillWidth: true
          implicitHeight: headerCol.implicitHeight + 24

          ColumnLayout {
            id: headerCol
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            RowLayout {
              Layout.fillWidth: true
              spacing: 10

              Rectangle {
                implicitWidth: 36
                implicitHeight: 36
                radius: 18
                color: Theme.alpha(Theme.accent, 0.16)
                border.width: 1
                border.color: Theme.alpha(Theme.accent, 0.3)
                Image {
                  anchors.centerIn: parent
                  width: 18
                  height: 18
                  source: Stylix.nixIcon
                  smooth: true
                  mipmap: true
                }
              }

              ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Label {
                  text: Quickshell.env("USER") + "@" + hostFile.text().trim()
                  monospace: true
                  font.weight: Font.Bold
                }
                Label {
                  text: win.uptime
                  size: Theme.fontSmall
                  color: Theme.muted
                }
              }

              // Ambient weather chip.
              Rectangle {
                visible: Weather.ready
                implicitWidth: weatherChip.implicitWidth + 16
                implicitHeight: 30
                radius: 15
                color: Theme.card
                border.width: 1
                border.color: Theme.cardBorder

                RowLayout {
                  id: weatherChip
                  anchors.centerIn: parent
                  spacing: 6
                  Glyph {
                    glyph: Weather.glyphFor(Weather.code, Weather.isDay)
                    size: 14
                    color: Theme.warn
                  }
                  Label {
                    text: Weather.temp + "°"
                    monospace: true
                    size: 12
                    font.weight: Font.DemiBold
                  }
                  Label {
                    text: Weather.location
                    size: Theme.fontSmall
                    color: Theme.muted
                  }
                }
              }

              IconButton {
                size: 32
                glyph: Theme.iLock
                onClicked: { Ui.closeControl(); Quickshell.execDetached(["loginctl", "lock-session"]); }
              }
              IconButton {
                size: 32
                glyph: Theme.iPower
                tint: Theme.danger
                onClicked: Ui.toggleSession()
              }
            }

            // Segmented navigation tabs.
            RowLayout {
              Layout.fillWidth: true
              spacing: 6

              Repeater {
                model: [
                  { id: "overview",  label: "Overview",  glyph: Theme.iDashboard },
                  { id: "services",  label: "Services",  glyph: Theme.iServer },
                  { id: "displays",  label: "Displays",  glyph: Theme.iMonitor },
                  { id: "wallpaper", label: "Wallpaper", glyph: Theme.iImage },
                  { id: "ai",        label: "AI",        glyph: Theme.iRobot }
                ]

                Rectangle {
                  required property var modelData
                  readonly property bool active: win.tab === modelData.id

                  Layout.fillWidth: true
                  implicitHeight: 32
                  radius: Theme.radiusSmall
                  color: active
                    ? Theme.alpha(Theme.accent, 0.2)
                    : tabMouse.containsMouse ? Theme.hover : Theme.card
                  border.width: 1
                  border.color: active ? Theme.alpha(Theme.accent, 0.4) : Theme.cardBorder
                  Behavior on color { ColorAnimation { duration: Theme.anim } }

                  RowLayout {
                    anchors.centerIn: parent
                    spacing: 5
                    Glyph {
                      glyph: modelData.glyph
                      size: 13
                      color: active ? Theme.accent : Theme.muted
                    }
                    Label {
                      text: modelData.label
                      size: 11
                      font.weight: active ? Font.DemiBold : Font.Normal
                      color: active ? Theme.bright : Theme.muted
                    }
                  }

                  MouseArea {
                    id: tabMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      Ui.controlTab = modelData.id;
                      if (modelData.id === "services") { Tailscale.refresh(); Docker.refresh(); }
                      else if (modelData.id === "displays") Displays.refresh();
                      else if (modelData.id === "wallpaper") Wallpapers.refresh();
                      else if (modelData.id === "ai") Usage.refresh();
                    }
                  }
                }
              }
            }
          }
        }

        // ───────────────────────────────────────────────────────────────────
        // TAB 1: OVERVIEW — Asymmetric Bento Islands + Slim Media Ribbon
        // ───────────────────────────────────────────────────────────────────
        ColumnLayout {
          Layout.fillWidth: true
          Layout.fillHeight: true
          visible: win.tab === "overview"
          spacing: 10

          RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            // ISLAND A: Quick Controls (2x3 tiles).
            BentoCard {
              Layout.preferredWidth: 276
              Layout.fillHeight: true

              ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                Label {
                  text: "QUICK CONTROLS"
                  monospace: true
                  size: 10
                  font.weight: Font.Bold
                  color: Theme.faint
                }

                GridLayout {
                  Layout.fillWidth: true
                  Layout.fillHeight: true
                  columns: 2
                  columnSpacing: 6
                  rowSpacing: 6

                  Tile {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    implicitHeight: 54
                    glyph: Network.icon()
                    title: Network.connected ? (Network.type === "ethernet" ? "Ethernet" : Network.name) : "Network"
                    detail: Network.connected
                      ? (Network.type === "wifi" && Network.signal >= 0 ? Network.signal + "%" : "Online")
                      : "Offline"
                    active: Network.connected
                    onClicked: { Ui.closeControl(); Ui.run(["nm-connection-editor"]); }
                  }
                  Tile {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    implicitHeight: 54
                    glyph: Theme.iBluetooth
                    title: "Bluetooth"
                    detail: "Devices"
                    onClicked: { Ui.closeControl(); Ui.run(["blueman-manager"]); }
                  }
                  Tile {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    implicitHeight: 54
                    glyph: Theme.iCoffee
                    title: "Awake"
                    detail: Ui.keepAwake ? "Active" : "Off"
                    active: Ui.keepAwake
                    tint: Theme.warn
                    onClicked: Ui.keepAwake = !Ui.keepAwake
                  }
                  Tile {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    implicitHeight: 54
                    glyph: Recorder.active ? Theme.iStop : Theme.iRecord
                    title: Recorder.active ? "Stop" : "Record"
                    detail: Recorder.active ? Recorder.clock(Recorder.elapsed) : "Screen"
                    active: Recorder.active
                    tint: Theme.danger
                    onClicked: { Ui.closeControl(); Recorder.toggle(); }
                  }
                  Tile {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    implicitHeight: 54
                    glyph: Theme.iCamera
                    title: "Capture"
                    detail: "Region"
                    onClicked: { Ui.closeControl(); Quickshell.execDetached(["hypr-screenshot"]); }
                  }
                  Tile {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    implicitHeight: 54
                    glyph: Theme.iGauge
                    title: "Monitor"
                    detail: "Processes"
                    onClicked: { Ui.closeControl(); Ui.run(["missioncenter"]); }
                  }
                }
              }
            }

            // Right stack: Sound (top) + Telemetry & AI Pulse (bottom).
            ColumnLayout {
              Layout.fillWidth: true
              Layout.fillHeight: true
              spacing: 10

              // ISLAND B: Sound & Devices.
              BentoCard {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                  anchors.fill: parent
                  anchors.margins: 12
                  spacing: 8

                  RowLayout {
                    Layout.fillWidth: true
                    Label {
                      text: "SOUND"
                      monospace: true
                      size: 10
                      font.weight: Font.Bold
                      color: Theme.faint
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                      implicitWidth: mixerRow.implicitWidth + 12
                      implicitHeight: 22
                      radius: 6
                      color: mixerMouse.containsMouse ? Theme.hover : Theme.card
                      border.width: 1
                      border.color: Theme.cardBorder
                      RowLayout {
                        id: mixerRow
                        anchors.centerIn: parent
                        spacing: 4
                        Glyph { glyph: Theme.iTune; size: 11; color: Theme.muted }
                        Label { text: "Mixer"; size: 10; color: Theme.muted }
                      }
                      MouseArea {
                        id: mixerMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { Ui.closeControl(); Ui.run(["pavucontrol"]); }
                      }
                    }
                  }

                  // Output channel.
                  ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3

                    RowLayout {
                      Layout.fillWidth: true
                      Label {
                        Layout.fillWidth: true
                        text: Audio.sinkName
                        size: 12
                        font.weight: Font.DemiBold
                      }
                      Label {
                        text: Audio.muted ? "Muted" : Math.round(Audio.volume * 100) + "%"
                        monospace: true
                        size: 11
                        color: Audio.muted ? Theme.faint : Theme.accent
                      }
                    }
                    RowLayout {
                      Layout.fillWidth: true
                      spacing: 8
                      IconButton {
                        size: 26
                        glyph: Audio.icon(Audio.volume, Audio.muted)
                        tint: Audio.muted ? Theme.faint : Theme.text
                        onClicked: Audio.toggleMute(Audio.sink)
                      }
                      Slider {
                        Layout.fillWidth: true
                        value: Audio.volume
                        dimmed: Audio.muted
                        onMoved: v => Audio.setVolume(Audio.sink, v)
                      }
                    }
                  }

                  Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: Theme.cardBorder
                  }

                  // Input channel.
                  ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3

                    RowLayout {
                      Layout.fillWidth: true
                      Label {
                        Layout.fillWidth: true
                        text: Audio.sourceName
                        size: 12
                        font.weight: Font.DemiBold
                      }
                      Label {
                        text: Audio.micMuted ? "Muted" : Math.round(Audio.micVolume * 100) + "%"
                        monospace: true
                        size: 11
                        color: Audio.micMuted ? Theme.faint : Theme.accentAlt
                      }
                    }
                    RowLayout {
                      Layout.fillWidth: true
                      spacing: 8
                      IconButton {
                        size: 26
                        glyph: Audio.micMuted ? Theme.iMicOff : Theme.iMic
                        tint: Audio.micMuted ? Theme.faint : Theme.text
                        onClicked: Audio.toggleMute(Audio.source)
                      }
                      Slider {
                        Layout.fillWidth: true
                        value: Audio.micVolume
                        dimmed: Audio.micMuted
                        onMoved: v => Audio.setVolume(Audio.source, v)
                      }
                    }
                  }

                  Item { Layout.fillHeight: true }
                }
              }

              // ISLAND C: Telemetry Rings + AI Pulse.
              BentoCard {
                Layout.fillWidth: true
                implicitHeight: 158

                ColumnLayout {
                  anchors.fill: parent
                  anchors.margins: 12
                  spacing: 8

                  RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                      model: [
                        { label: "CPU", val: Stats.cpu, sub: "load" },
                        { label: "RAM", val: Stats.mem, sub: "used" },
                        { label: "GPU", val: Math.max(0, Stats.gpu), sub: Stats.gpuTemp >= 0 ? Stats.gpuTemp + "°C" : "idle" }
                      ]

                      ColumnLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 3

                        Item {
                          Layout.alignment: Qt.AlignHCenter
                          implicitWidth: 46
                          implicitHeight: 46

                          Ring {
                            anchors.fill: parent
                            value: modelData.val / 100
                            fill: Theme.level(modelData.val)
                            thickness: 4
                          }
                          Label {
                            anchors.centerIn: parent
                            text: modelData.val + "%"
                            monospace: true
                            size: 11
                            font.weight: Font.Bold
                            color: Theme.bright
                          }
                        }
                        Label {
                          Layout.alignment: Qt.AlignHCenter
                          text: modelData.label + " · " + modelData.sub
                          monospace: true
                          size: 9
                          color: Theme.muted
                        }
                      }
                    }
                  }

                  Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: Theme.cardBorder
                  }

                  // Compact AI quota strip (clicks through to AI tab).
                  Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Theme.radiusSmall
                    color: aiStripMouse.containsMouse ? Theme.hover : Theme.card
                    border.width: 1
                    border.color: Theme.cardBorder

                    RowLayout {
                      anchors.fill: parent
                      anchors.leftMargin: 10
                      anchors.rightMargin: 10
                      spacing: 10

                      Glyph { glyph: Theme.iRobot; size: 14; color: Theme.accent }

                      Repeater {
                        model: Usage.ready.slice(0, 3)

                        ColumnLayout {
                          required property var modelData
                          readonly property var primary: Usage.primaryMetric(modelData)
                          readonly property real pct: primary?.percent ?? 0
                          Layout.fillWidth: true
                          spacing: 2

                          RowLayout {
                            Layout.fillWidth: true
                            Label {
                              text: modelData.display_name.split(" ")[0]
                              size: 10
                              color: modelData.stale ? Theme.faint : Theme.muted
                              Layout.fillWidth: true
                            }
                            Label {
                              text: Math.round(pct) + "%"
                              monospace: true
                              size: 10
                              color: modelData.stale ? Theme.faint : Theme.level(pct)
                            }
                          }
                          Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 4
                            radius: 2
                            color: Theme.alpha(Theme.text, 0.1)
                            Rectangle {
                              width: parent.width * Math.min(1, pct / 100)
                              height: parent.height
                              radius: 2
                              color: modelData.stale ? Theme.faint : Theme.level(pct)
                            }
                          }
                        }
                      }

                      Label {
                        visible: Usage.ready.length === 0
                        Layout.fillWidth: true
                        text: "AI Quotas"
                        size: 11
                        color: Theme.muted
                      }

                      Glyph { glyph: Theme.iChevronRight; size: 14; color: Theme.faint }
                    }

                    MouseArea {
                      id: aiStripMouse
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: { Ui.controlTab = "ai"; Usage.refresh(); }
                    }
                  }
                }
              }
            }
          }

          // ISLAND D: Slim Now Playing Ribbon (only shown when media is active).
          BentoCard {
            Layout.fillWidth: true
            implicitHeight: 60
            visible: Media.player !== null

            Image {
              anchors.fill: parent
              visible: (Media.player?.trackArtUrl ?? "") !== ""
              source: Media.player?.trackArtUrl ?? ""
              fillMode: Image.PreserveAspectCrop
              opacity: 0.14
              asynchronous: true
              sourceSize.width: 480
              sourceSize.height: 80
            }

            Rectangle {
              anchors.fill: parent
              gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Theme.alpha(Theme.bg, 0.35) }
                GradientStop { position: 1.0; color: Theme.alpha(Theme.bg, 0.72) }
              }
            }

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 10
              anchors.rightMargin: 12
              spacing: 10

              ClippingRectangle {
                implicitWidth: 40
                implicitHeight: 40
                radius: Theme.radiusSmall
                color: Theme.alpha(Theme.accent, 0.16)
                Glyph { anchors.centerIn: parent; glyph: Theme.iMusic; size: 16; color: Theme.accent }
                Image {
                  anchors.fill: parent
                  source: Media.player?.trackArtUrl ?? ""
                  fillMode: Image.PreserveAspectCrop
                  asynchronous: true
                  sourceSize.width: 80
                  sourceSize.height: 80
                }
              }

              ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Label {
                  Layout.fillWidth: true
                  text: Media.title || "Unknown track"
                  size: 12
                  font.weight: Font.DemiBold
                  color: Theme.bright
                }
                Label {
                  Layout.fillWidth: true
                  text: Media.artist || (Media.player?.isPlaying ? "Playing" : "Paused")
                  size: 11
                  color: Theme.muted
                }
              }

              Row {
                spacing: 2
                height: 18
                visible: Cava.active
                Repeater {
                  model: Cava.bars
                  Rectangle {
                    required property real modelData
                    anchors.bottom: parent.bottom
                    width: 2.5
                    height: Math.max(2, Math.round(modelData * 18))
                    radius: 1.25
                    color: Theme.alpha(Theme.accent, 0.45 + modelData * 0.55)
                    Behavior on height { NumberAnimation { duration: 45 } }
                  }
                }
              }

              RowLayout {
                spacing: 2
                IconButton { size: 26; glyph: Theme.iPrev; onClicked: Media.player?.previous() }
                Rectangle {
                  implicitWidth: 30
                  implicitHeight: 30
                  radius: 15
                  color: playMouse.containsMouse ? Theme.alpha(Theme.accent, 0.35) : Theme.alpha(Theme.accent, 0.22)
                  border.width: 1
                  border.color: Theme.alpha(Theme.accent, 0.45)
                  Glyph {
                    anchors.centerIn: parent
                    glyph: Media.player?.isPlaying ? Theme.iPause : Theme.iPlay
                    size: 14
                    color: Theme.accent
                  }
                  MouseArea {
                    id: playMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Media.player?.togglePlaying()
                  }
                }
                IconButton { size: 26; glyph: Theme.iNext; onClicked: Media.player?.next() }
              }
            }
          }
        }

        // ───────────────────────────────────────────────────────────────────
        // TAB 2: SERVICES — Tailscale + Docker Bento Islands
        // ───────────────────────────────────────────────────────────────────
        RowLayout {
          Layout.fillWidth: true
          Layout.fillHeight: true
          visible: win.tab === "services"
          spacing: 10

          // TAILSCALE ISLAND
          BentoCard {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: 12
              spacing: 8

              RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Glyph {
                  glyph: Theme.iVpn
                  size: 16
                  color: Tailscale.connected ? Theme.good : Theme.muted
                }
                Label {
                  text: "TAILSCALE"
                  monospace: true
                  size: 10
                  font.weight: Font.Bold
                  color: Theme.faint
                }
                Item { Layout.fillWidth: true }

                Rectangle {
                  visible: Tailscale.available
                  implicitWidth: tsToggleLbl.implicitWidth + 14
                  implicitHeight: 24
                  radius: 7
                  color: Tailscale.connected
                    ? Theme.alpha(Theme.good, 0.2)
                    : tsToggleMouse.containsMouse ? Theme.hover : Theme.card
                  border.width: 1
                  border.color: Tailscale.connected ? Theme.alpha(Theme.good, 0.45) : Theme.cardBorder

                  Label {
                    id: tsToggleLbl
                    anchors.centerIn: parent
                    monospace: true
                    size: 10
                    font.weight: Font.DemiBold
                    color: Tailscale.connected ? Theme.good : Theme.muted
                    text: Tailscale.busy ? "..." : Tailscale.connected ? "Connected" : "Offline"
                  }
                  MouseArea {
                    id: tsToggleMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Tailscale.toggle()
                  }
                }
              }

              // Self IP chip (click to copy).
              Rectangle {
                visible: Tailscale.selfIp !== ""
                Layout.fillWidth: true
                implicitHeight: 32
                radius: Theme.radiusSmall
                color: selfIpMouse.containsMouse ? Theme.hover : Theme.card
                border.width: 1
                border.color: Theme.cardBorder

                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: 10
                  anchors.rightMargin: 10
                  spacing: 6
                  Label {
                    text: Tailscale.selfName || "This device"
                    size: 11
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                  }
                  Label {
                    text: Tailscale.selfIp
                    monospace: true
                    size: 11
                    color: Theme.accent
                  }
                  Glyph { glyph: Theme.iCopy; size: 12; color: Theme.muted }
                }
                MouseArea {
                  id: selfIpMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: Tailscale.copyIp(Tailscale.selfIp)
                }
              }

              // Active exit node banner.
              Rectangle {
                visible: Tailscale.exitNode !== ""
                Layout.fillWidth: true
                implicitHeight: 26
                radius: 6
                color: Theme.alpha(Theme.warn, 0.16)
                border.width: 1
                border.color: Theme.alpha(Theme.warn, 0.35)

                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: 8
                  anchors.rightMargin: 8
                  Label {
                    Layout.fillWidth: true
                    text: "Exit: " + Tailscale.exitNode
                    size: 11
                    color: Theme.warn
                  }
                  Label {
                    text: "Clear"
                    monospace: true
                    size: 10
                    color: Theme.bright
                    MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: Tailscale.setExitNode("")
                    }
                  }
                }
              }

              Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: peerCol.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                  id: peerCol
                  width: parent.width
                  spacing: 6

                  Repeater {
                    model: Tailscale.peers

                    Rectangle {
                      required property var modelData
                      Layout.fillWidth: true
                      implicitHeight: 42
                      radius: Theme.radiusSmall
                      color: peerMouse.containsMouse ? Theme.hover : Theme.card
                      border.width: 1
                      border.color: modelData.exitNode ? Theme.alpha(Theme.warn, 0.45) : Theme.cardBorder

                      RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 8
                        spacing: 8

                        Rectangle {
                          width: 7; height: 7; radius: 3.5
                          color: modelData.online ? Theme.good : Theme.faint
                        }
                        ColumnLayout {
                          Layout.fillWidth: true
                          spacing: 1
                          Label {
                            Layout.fillWidth: true
                            text: modelData.name
                            size: 11
                            font.weight: Font.DemiBold
                            color: modelData.online ? Theme.text : Theme.muted
                          }
                          Label {
                            Layout.fillWidth: true
                            text: modelData.ip + (modelData.os ? " · " + modelData.os : "")
                            monospace: true
                            size: 9
                            color: Theme.faint
                          }
                        }

                        Rectangle {
                          visible: modelData.exitNodeOption && modelData.online
                          implicitWidth: exitLbl.implicitWidth + 10
                          implicitHeight: 20
                          radius: 5
                          color: modelData.exitNode ? Theme.alpha(Theme.warn, 0.24) : Theme.alpha(Theme.bg, 0.4)
                          border.width: 1
                          border.color: modelData.exitNode ? Theme.alpha(Theme.warn, 0.5) : Theme.cardBorder
                          Label {
                            id: exitLbl
                            anchors.centerIn: parent
                            monospace: true
                            size: 9
                            color: modelData.exitNode ? Theme.warn : Theme.muted
                            text: modelData.exitNode ? "Exit ✓" : "Exit"
                          }
                          MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Tailscale.setExitNode(modelData.exitNode ? "" : modelData.ip)
                          }
                        }
                      }

                      MouseArea {
                        id: peerMouse
                        anchors.fill: parent
                        z: -1
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Tailscale.copyIp(modelData.ip)
                      }
                    }
                  }
                }
              }
            }
          }

          // DOCKER ISLAND
          BentoCard {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: 12
              spacing: 8

              RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Glyph {
                  glyph: Theme.iDocker
                  size: 16
                  color: Docker.runningCount > 0 ? Theme.accent : Theme.muted
                }
                Label {
                  text: "DOCKER"
                  monospace: true
                  size: 10
                  font.weight: Font.Bold
                  color: Theme.faint
                }
                Rectangle {
                  visible: Docker.available
                  implicitWidth: dCountLbl.implicitWidth + 10
                  implicitHeight: 18
                  radius: 6
                  color: Theme.alpha(Theme.accent, 0.16)
                  Label {
                    id: dCountLbl
                    anchors.centerIn: parent
                    monospace: true
                    size: 9
                    color: Theme.accent
                    text: Docker.runningCount + " / " + Docker.containers.length
                  }
                }
                Item { Layout.fillWidth: true }
                IconButton {
                  size: 24
                  glyph: Theme.iRefresh
                  onClicked: Docker.refresh()
                }
              }

              Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: Docker.containers.length === 0
                Label {
                  anchors.centerIn: parent
                  text: Docker.available ? "No containers" : "Docker unavailable"
                  size: 12
                  color: Theme.muted
                }
              }

              Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: Docker.containers.length > 0
                contentHeight: dockerCol.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                  id: dockerCol
                  width: parent.width
                  spacing: 6

                  Repeater {
                    model: Docker.containers

                    Rectangle {
                      required property var modelData
                      Layout.fillWidth: true
                      implicitHeight: 46
                      radius: Theme.radiusSmall
                      color: Theme.card
                      border.width: 1
                      border.color: modelData.running ? Theme.alpha(Theme.good, 0.3) : Theme.cardBorder

                      RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 8
                        spacing: 8

                        Rectangle {
                          width: 7; height: 7; radius: 3.5
                          color: modelData.running ? Theme.good : Theme.faint
                        }

                        ColumnLayout {
                          Layout.fillWidth: true
                          spacing: 1
                          Label {
                            Layout.fillWidth: true
                            text: modelData.name
                            size: 11
                            font.weight: Font.DemiBold
                            color: modelData.running ? Theme.bright : Theme.muted
                          }
                          Label {
                            Layout.fillWidth: true
                            text: modelData.image + " · " + modelData.status
                            monospace: true
                            size: 9
                            color: Theme.faint
                          }
                        }

                        IconButton {
                          visible: modelData.running
                          size: 24
                          glyph: Theme.iRefresh
                          tint: Theme.muted
                          onClicked: Docker.restart(modelData.id)
                        }
                        IconButton {
                          size: 24
                          glyph: modelData.running ? Theme.iStop : Theme.iPlay
                          tint: modelData.running ? Theme.danger : Theme.good
                          onClicked: modelData.running ? Docker.stop(modelData.id) : Docker.start(modelData.id)
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }

        // ───────────────────────────────────────────────────────────────────
        // TAB 3: DISPLAYS ISLAND
        // ───────────────────────────────────────────────────────────────────
        BentoCard {
          Layout.fillWidth: true
          Layout.fillHeight: true
          visible: win.tab === "displays"

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            RowLayout {
              Layout.fillWidth: true
              spacing: 8

              Label {
                text: "DISPLAYS"
                monospace: true
                size: 10
                font.weight: Font.Bold
                color: Theme.faint
              }
              Item { Layout.fillWidth: true }

              IconButton {
                size: 26
                glyph: Theme.iRefresh
                onClicked: Displays.refresh()
              }

              Rectangle {
                implicitWidth: layoutBtnRow.implicitWidth + 14
                implicitHeight: 26
                radius: 7
                color: layoutBtnMouse.containsMouse ? Theme.alpha(Theme.accent, 0.25) : Theme.alpha(Theme.accent, 0.14)
                border.width: 1
                border.color: Theme.alpha(Theme.accent, 0.35)

                RowLayout {
                  id: layoutBtnRow
                  anchors.centerIn: parent
                  spacing: 6
                  Glyph { glyph: Theme.iMonitor; size: 13; color: Theme.accent }
                  Label { text: "Arrange (nwg-displays)"; size: 11; font.weight: Font.DemiBold; color: Theme.accent }
                }
                MouseArea {
                  id: layoutBtnMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: { Ui.closeControl(); Ui.run(["nwg-displays"]); }
                }
              }
            }

            Flickable {
              Layout.fillWidth: true
              Layout.fillHeight: true
              contentHeight: dispCol.implicitHeight
              clip: true
              boundsBehavior: Flickable.StopAtBounds

              ColumnLayout {
                id: dispCol
                width: parent.width
                spacing: 10

                Repeater {
                  model: Displays.monitors

                  Rectangle {
                    required property var modelData
                    readonly property var mon: modelData

                    Layout.fillWidth: true
                    implicitHeight: monCol.implicitHeight + 20
                    radius: Theme.radiusSmall
                    color: Theme.card
                    border.width: 1
                    border.color: mon.focused ? Theme.alpha(Theme.accent, 0.4) : Theme.cardBorder

                    ColumnLayout {
                      id: monCol
                      anchors.fill: parent
                      anchors.margins: 10
                      spacing: 8

                      RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Glyph { glyph: Theme.iMonitor; size: 18; color: mon.focused ? Theme.accent : Theme.muted }
                        ColumnLayout {
                          Layout.fillWidth: true
                          spacing: 1
                          Label {
                            text: mon.name + (mon.focused ? " · Primary" : "")
                            font.weight: Font.DemiBold
                          }
                          Label {
                            text: mon.description || (mon.width + "×" + mon.height)
                            size: Theme.fontSmall
                            color: Theme.muted
                          }
                        }
                        Rectangle {
                          implicitWidth: specLbl.implicitWidth + 12
                          implicitHeight: 22
                          radius: 6
                          color: Theme.alpha(Theme.accent, 0.14)
                          Label {
                            id: specLbl
                            anchors.centerIn: parent
                            monospace: true
                            size: 10
                            color: Theme.accent
                            text: mon.width + "×" + mon.height + " @ " + Math.round(mon.refreshRate) + "Hz"
                          }
                        }
                      }

                      // Scale pills.
                      RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        Label { text: "Scale"; size: 11; color: Theme.muted; Layout.preferredWidth: 44 }
                        Repeater {
                          model: [1, 1.25, 1.5, 2]
                          Rectangle {
                            required property real modelData
                            readonly property bool selected: Math.abs((mon.scale ?? 1) - modelData) < 0.02
                            implicitWidth: 48
                            implicitHeight: 24
                            radius: 6
                            color: selected ? Theme.alpha(Theme.accent, 0.22) : scaleMouse.containsMouse ? Theme.hover : Theme.alpha(Theme.bg, 0.35)
                            border.width: 1
                            border.color: selected ? Theme.alpha(Theme.accent, 0.45) : Theme.cardBorder
                            Label {
                              anchors.centerIn: parent
                              monospace: true
                              size: 11
                              color: selected ? Theme.accent : Theme.text
                              text: modelData + "×"
                            }
                            MouseArea {
                              id: scaleMouse
                              anchors.fill: parent
                              hoverEnabled: true
                              cursorShape: Qt.PointingHandCursor
                              onClicked: Displays.setScale(mon, modelData)
                            }
                          }
                        }
                        Item { Layout.fillWidth: true }
                      }

                      // Top available modes.
                      RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        visible: Displays.topModes(mon).length > 0
                        Label { text: "Mode"; size: 11; color: Theme.muted; Layout.preferredWidth: 44 }
                        Flow {
                          Layout.fillWidth: true
                          spacing: 6
                          Repeater {
                            model: Displays.topModes(mon)
                            Rectangle {
                              required property string modelData
                              readonly property string currentPrefix: mon.width + "x" + mon.height + "@" + Math.round(mon.refreshRate)
                              readonly property bool selected: modelData.startsWith(currentPrefix)
                              implicitWidth: modeLbl.implicitWidth + 12
                              implicitHeight: 24
                              radius: 6
                              color: selected ? Theme.alpha(Theme.accentAlt, 0.22) : modeMouse.containsMouse ? Theme.hover : Theme.alpha(Theme.bg, 0.35)
                              border.width: 1
                              border.color: selected ? Theme.alpha(Theme.accentAlt, 0.45) : Theme.cardBorder
                              Label {
                                id: modeLbl
                                anchors.centerIn: parent
                                monospace: true
                                size: 10
                                color: selected ? Theme.accentAlt : Theme.muted
                                text: modelData
                              }
                              MouseArea {
                                id: modeMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Displays.setMode(mon, modelData)
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }

        // ───────────────────────────────────────────────────────────────────
        // TAB 3: WALLPAPER GALLERY ISLAND
        // ───────────────────────────────────────────────────────────────────
        BentoCard {
          Layout.fillWidth: true
          Layout.fillHeight: true
          visible: win.tab === "wallpaper"

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            RowLayout {
              Layout.fillWidth: true
              spacing: 8

              Label {
                text: "WALLPAPERS"
                monospace: true
                size: 10
                font.weight: Font.Bold
                color: Theme.faint
              }
              Label {
                text: "~/Pictures/Wallpapers"
                monospace: true
                size: 10
                color: Theme.muted
              }
              Item { Layout.fillWidth: true }

              IconButton {
                size: 26
                glyph: Theme.iRefresh
                onClicked: Wallpapers.refresh()
              }

              Rectangle {
                implicitWidth: folderBtnRow.implicitWidth + 12
                implicitHeight: 26
                radius: 7
                color: folderBtnMouse.containsMouse ? Theme.hover : Theme.card
                border.width: 1
                border.color: Theme.cardBorder
                RowLayout {
                  id: folderBtnRow
                  anchors.centerIn: parent
                  spacing: 5
                  Glyph { glyph: Theme.iFolder; size: 12; color: Theme.muted }
                  Label { text: "Folder"; size: 11; color: Theme.text }
                }
                MouseArea {
                  id: folderBtnMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: { Ui.closeControl(); Wallpapers.openFolder(); }
                }
              }

              Rectangle {
                implicitWidth: resetLbl.implicitWidth + 14
                implicitHeight: 26
                radius: 7
                color: Wallpapers.isDefault
                  ? Theme.alpha(Theme.accent, 0.2)
                  : resetMouse.containsMouse ? Theme.hover : Theme.card
                border.width: 1
                border.color: Wallpapers.isDefault ? Theme.alpha(Theme.accent, 0.45) : Theme.cardBorder
                Label {
                  id: resetLbl
                  anchors.centerIn: parent
                  text: "NixOS Default"
                  size: 11
                  color: Wallpapers.isDefault ? Theme.accent : Theme.muted
                }
                MouseArea {
                  id: resetMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: Wallpapers.reset()
                }
              }
            }

            // Empty folder state with preview of the active NixOS wallpaper.
            Item {
              Layout.fillWidth: true
              Layout.fillHeight: true
              visible: Wallpapers.items.length === 0

              ColumnLayout {
                anchors.centerIn: parent
                spacing: 10

                ClippingRectangle {
                  Layout.alignment: Qt.AlignHCenter
                  implicitWidth: 220
                  implicitHeight: 110
                  radius: Theme.radiusSmall
                  color: Theme.card
                  Image {
                    anchors.fill: parent
                    source: "file://" + Wallpapers.active
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: 440
                    sourceSize.height: 220
                  }
                }

                Label {
                  Layout.alignment: Qt.AlignHCenter
                  text: "Drop images into ~/Pictures/Wallpapers"
                  font.weight: Font.DemiBold
                }
                Label {
                  Layout.alignment: Qt.AlignHCenter
                  text: "PNG, JPG, and WebP show up here for one-click switching"
                  size: Theme.fontSmall
                  color: Theme.muted
                }
              }
            }

            // Thumbnail grid.
            Flickable {
              Layout.fillWidth: true
              Layout.fillHeight: true
              visible: Wallpapers.items.length > 0
              contentHeight: wallGrid.implicitHeight
              clip: true
              boundsBehavior: Flickable.StopAtBounds

              GridLayout {
                id: wallGrid
                width: parent.width
                columns: 3
                columnSpacing: 8
                rowSpacing: 8

                Repeater {
                  model: Wallpapers.items

                  Rectangle {
                    required property var modelData
                    readonly property bool selected: Wallpapers.active === modelData.path

                    Layout.fillWidth: true
                    implicitHeight: 96
                    radius: Theme.radiusSmall
                    color: Theme.card
                    border.width: selected ? 2 : 1
                    border.color: selected ? Theme.accent : wallMouse.containsMouse ? Theme.alpha(Theme.bright, 0.3) : Theme.cardBorder

                    ClippingRectangle {
                      anchors.fill: parent
                      anchors.margins: selected ? 2 : 1
                      radius: Theme.radiusSmall - 1

                      Image {
                        anchors.fill: parent
                        source: "file://" + modelData.path
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize.width: 320
                        sourceSize.height: 180
                      }

                      Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 24
                        gradient: Gradient {
                          GradientStop { position: 0.0; color: "transparent" }
                          GradientStop { position: 1.0; color: Theme.alpha(Theme.bg, 0.85) }
                        }
                        Label {
                          anchors.left: parent.left
                          anchors.right: parent.right
                          anchors.bottom: parent.bottom
                          anchors.margins: 5
                          text: modelData.name
                          size: 10
                          color: Theme.bright
                        }
                      }
                    }

                    Rectangle {
                      visible: selected
                      anchors.top: parent.top
                      anchors.right: parent.right
                      anchors.margins: 6
                      width: 20
                      height: 20
                      radius: 10
                      color: Theme.accent
                      Glyph {
                        anchors.centerIn: parent
                        glyph: Theme.iCheck
                        size: 12
                        color: Theme.bg
                      }
                    }

                    MouseArea {
                      id: wallMouse
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: Wallpapers.select(modelData.path)
                    }
                  }
                }
              }
            }
          }
        }

        // ───────────────────────────────────────────────────────────────────
        // TAB 4: AI QUOTAS ISLAND
        // ───────────────────────────────────────────────────────────────────
        BentoCard {
          Layout.fillWidth: true
          Layout.fillHeight: true
          visible: win.tab === "ai"

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            RowLayout {
              Layout.fillWidth: true
              Label {
                text: "AI PLAN QUOTAS"
                monospace: true
                size: 10
                font.weight: Font.Bold
                color: Theme.faint
              }
              Item { Layout.fillWidth: true }
              IconButton {
                size: 26
                glyph: Theme.iRefresh
                visible: !Usage.loading
                onClicked: Usage.refresh()
              }
            }

            Flickable {
              Layout.fillWidth: true
              Layout.fillHeight: true
              contentHeight: aiCol.implicitHeight
              clip: true
              boundsBehavior: Flickable.StopAtBounds

              ColumnLayout {
                id: aiCol
                width: parent.width
                spacing: 8

                Repeater {
                  model: Usage.entries

                  Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: usageCol.implicitHeight + 20
                    radius: Theme.radiusSmall
                    color: Theme.card
                    border.width: 1
                    border.color: Theme.cardBorder

                    ColumnLayout {
                      id: usageCol
                      anchors.fill: parent
                      anchors.margins: 10
                      spacing: 8

                      RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Label { text: modelData.display_name; font.weight: Font.DemiBold }
                        Label { text: modelData.plan ?? ""; color: Theme.muted; size: Theme.fontSmall; Layout.fillWidth: true }
                        Rectangle {
                          visible: modelData.stale === true
                          implicitWidth: staleLbl.implicitWidth + 10
                          implicitHeight: 18
                          radius: 6
                          color: Theme.alpha(Theme.warn, 0.16)
                          Label {
                            id: staleLbl
                            anchors.centerIn: parent
                            monospace: true
                            size: 9
                            color: Theme.warn
                            text: modelData.cached_at ? "cached · " + Ui.ago(modelData.cached_at) : "cached"
                          }
                        }
                      }

                      Label {
                        Layout.fillWidth: true
                        visible: modelData.status !== "ready" && !modelData.stale
                        text: (modelData.error ?? modelData.status).split("\n")[0]
                        color: Theme.danger
                        size: Theme.fontSmall
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                      }

                      Repeater {
                        model: (modelData.metrics ?? []).filter(m => m.reset_at)

                        ColumnLayout {
                          required property var modelData
                          readonly property string winTag: Usage.windowLabel(modelData)
                          Layout.fillWidth: true
                          spacing: 3

                          RowLayout {
                            Layout.fillWidth: true
                            Label {
                              text: winTag ? modelData.label + " · " + winTag : modelData.label
                              size: 12
                              color: Theme.muted
                              Layout.fillWidth: true
                            }
                            Label { text: modelData.value; size: 12; monospace: true }
                          }
                          Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 5
                            radius: 3
                            color: Theme.alpha(Theme.text, 0.1)
                            Rectangle {
                              width: parent.width * Math.min(1, modelData.percent / 100)
                              height: parent.height
                              radius: parent.radius
                              color: Theme.level(modelData.percent)
                            }
                          }
                          Label {
                            Layout.fillWidth: true
                            text: modelData.detail.split(" · ")[0]
                            size: 10
                            color: Theme.faint
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
