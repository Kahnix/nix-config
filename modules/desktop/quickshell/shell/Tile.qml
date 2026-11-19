import QtQuick
import QtQuick.Layouts

// Quick-settings toggle: glyph, title and a one-line state.
Rectangle {
  id: root

  property string glyph
  property string title
  property string detail
  property bool active: false
  property color tint: Theme.accent
  signal clicked()

  implicitHeight: 56
  radius: Theme.radiusSmall
  color: active ? Theme.alpha(tint, 0.2) : mouse.containsMouse ? Theme.alpha(Theme.text, 0.09) : Theme.card
  border.width: 1
  border.color: active ? Theme.alpha(tint, 0.35) : Theme.cardBorder
  Behavior on color { ColorAnimation { duration: Theme.anim } }

  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: 14
    anchors.rightMargin: 12
    spacing: 12

    Glyph {
      glyph: root.glyph
      size: 18
      color: root.active ? root.tint : Theme.muted
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 1

      Label {
        Layout.fillWidth: true
        text: root.title
        font.weight: Font.DemiBold
      }
      Label {
        Layout.fillWidth: true
        text: root.detail
        size: Theme.fontSmall
        color: Theme.muted
      }
    }
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
