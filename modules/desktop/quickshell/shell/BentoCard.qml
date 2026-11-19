import QtQuick

// Floating bento island matching the bar's frosted-glass aesthetic with a
// subtle top specular hairline.
Rectangle {
  id: root

  property color tint: "transparent"

  radius: Theme.radius
  color: Theme.surface
  border.width: 1
  border.color: Theme.border
  clip: true

  Rectangle {
    anchors.fill: parent
    radius: parent.radius
    color: root.tint
  }

  Rectangle {
    anchors.top: parent.top
    anchors.topMargin: 1
    anchors.horizontalCenter: parent.horizontalCenter
    width: Math.max(0, parent.width - parent.radius * 2)
    height: 1
    color: Theme.alpha(Theme.bright, 0.08)
    z: 10
  }
}
