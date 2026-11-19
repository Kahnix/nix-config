import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

// Centered calendar & weather popover under the bar's clock.
PanelWindow {
  id: win

  readonly property date today: new Date()
  property int viewYear: today.getFullYear()
  property int viewMonth: today.getMonth()

  readonly property var cells: {
    const first = new Date(viewYear, viewMonth, 1);
    // Monday = 0 .. Sunday = 6
    const startOffset = (first.getDay() + 6) % 7;
    const daysInMonth = new Date(viewYear, viewMonth + 1, 0).getDate();
    const prevDays = new Date(viewYear, viewMonth, 0).getDate();
    const list = [];
    for (let i = startOffset - 1; i >= 0; i--)
      list.push({ day: prevDays - i, current: false, today: false });
    for (let d = 1; d <= daysInMonth; d++) {
      const isToday = d === today.getDate() && viewMonth === today.getMonth() && viewYear === today.getFullYear();
      list.push({ day: d, current: true, today: isToday });
    }
    while (list.length < 42)
      list.push({ day: list.length - startOffset - daysInMonth + 1, current: false, today: false });
    return list;
  }

  function stepMonth(delta) {
    let m = viewMonth + delta;
    let y = viewYear;
    if (m < 0) { m = 11; y--; }
    else if (m > 11) { m = 0; y++; }
    viewMonth = m;
    viewYear = y;
  }

  screen: Ui.activeScreen
  visible: Ui.calendarOpen || card.opacity > 0
  color: "transparent"
  WlrLayershell.namespace: "qs-calendar"
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.keyboardFocus: Ui.calendarOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore
  anchors { top: true }
  margins.top: Theme.barHeight + Theme.gap * 2
  implicitWidth: 320
  implicitHeight: card.implicitHeight

  HyprlandFocusGrab {
    windows: [win]
    active: Ui.calendarOpen
    onCleared: Ui.closeCalendar()
  }

  onVisibleChanged: {
    if (visible) {
      const now = new Date();
      viewYear = now.getFullYear();
      viewMonth = now.getMonth();
    }
  }

  Rectangle {
    id: card
    width: parent.width
    implicitHeight: content.implicitHeight + 32
    radius: Theme.radius
    color: Theme.surface
    border.width: 1
    border.color: Theme.border
    opacity: Ui.calendarOpen ? 1 : 0
    transform: Translate { y: Ui.calendarOpen ? 0 : -10; Behavior on y { NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic } } }
    Behavior on opacity { NumberAnimation { duration: Theme.anim } }

    focus: true
    Keys.onEscapePressed: Ui.closeCalendar()

    ColumnLayout {
      id: content
      anchors.fill: parent
      anchors.margins: 16
      spacing: 12

      // Weather summary card.
      Rectangle {
        Layout.fillWidth: true
        visible: Weather.ready
        implicitHeight: weatherRow.implicitHeight + 20
        radius: Theme.radiusSmall
        color: Theme.card
        border.width: 1
        border.color: Theme.cardBorder

        RowLayout {
          id: weatherRow
          anchors.fill: parent
          anchors.margins: 10
          spacing: 12

          Glyph {
            glyph: Weather.glyphFor(Weather.code, Weather.isDay)
            size: 24
            color: Theme.accent
          }
          ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            Label { text: Weather.condition; font.weight: Font.DemiBold }
            Label { text: Weather.location; size: Theme.fontSmall; color: Theme.muted }
          }
          Label {
            monospace: true
            size: 18
            font.weight: Font.Bold
            text: Weather.temp + "°"
            color: Theme.bright
          }
        }
      }

      // Month header + navigation.
      RowLayout {
        Layout.fillWidth: true

        IconButton {
          size: 28
          glyph: Theme.iChevronLeft
          onClicked: win.stepMonth(-1)
        }
        Label {
          Layout.fillWidth: true
          horizontalAlignment: Text.AlignHCenter
          font.weight: Font.DemiBold
          text: Qt.formatDate(new Date(win.viewYear, win.viewMonth, 1), "MMMM yyyy")
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              const now = new Date();
              win.viewYear = now.getFullYear();
              win.viewMonth = now.getMonth();
            }
          }
        }
        IconButton {
          size: 28
          glyph: Theme.iChevronRight
          onClicked: win.stepMonth(1)
        }
      }

      // Weekday headers.
      GridLayout {
        Layout.fillWidth: true
        columns: 7
        columnSpacing: 2
        rowSpacing: 4

        Repeater {
          model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
          Label {
            required property string modelData
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            monospace: true
            size: 10
            color: Theme.faint
            text: modelData
          }
        }

        Repeater {
          model: win.cells

          Rectangle {
            required property var modelData
            Layout.fillWidth: true
            implicitHeight: 30
            radius: Theme.radiusSmall
            color: modelData.today ? Theme.accent : "transparent"

            Label {
              anchors.centerIn: parent
              monospace: true
              size: 12
              text: modelData.day
              font.weight: modelData.today ? Font.Bold : Font.Normal
              color: modelData.today ? Theme.bg
                : modelData.current ? Theme.text
                : Theme.faint
            }
          }
        }
      }
    }
  }
}
