import QtQuick
import QtQuick.Layouts

Rectangle {
  id: root

  property alias text: input.text
  property alias echoMode: input.echoMode
  property string label: ""
  signal accepted()

  implicitHeight: 44
  radius: 4
  color: "#111116"
  border.width: 1
  border.color: input.activeFocus ? "#e46876" : "#363646"

  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: 12
    anchors.rightMargin: 12
    spacing: 12

    Text {
      Layout.preferredWidth: 64
      text: root.label
      color: "#727169"
      font.family: "Departure Mono"
      font.pixelSize: 8
    }

    TextInput {
      id: input
      Layout.fillWidth: true
      color: "#dcd7ba"
      selectionColor: "#7e9cd8"
      selectedTextColor: "#111116"
      font.family: "Departure Mono"
      font.pixelSize: 11
      verticalAlignment: TextInput.AlignVCenter
      clip: true
      onAccepted: root.accepted()
    }
  }

  TapHandler { onTapped: input.forceActiveFocus() }
}
