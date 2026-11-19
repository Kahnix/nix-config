import QtQuick

// Small progress ring; `value` is 0..1.
Canvas {
  id: root

  property real value: 0
  property color fill: Theme.accent
  property color track: Theme.alpha(Theme.text, 0.12)
  property real thickness: 2.5

  implicitWidth: 16
  implicitHeight: 16
  onValueChanged: requestPaint()
  onFillChanged: requestPaint()

  onPaint: {
    const ctx = getContext("2d");
    const r = Math.min(width, height) / 2 - thickness / 2;
    const start = -Math.PI / 2;
    ctx.reset();
    ctx.lineWidth = thickness;
    ctx.lineCap = "round";
    ctx.strokeStyle = track;
    ctx.beginPath();
    ctx.arc(width / 2, height / 2, r, 0, Math.PI * 2);
    ctx.stroke();
    if (value > 0) {
      ctx.strokeStyle = fill;
      ctx.beginPath();
      ctx.arc(width / 2, height / 2, r, start, start + Math.PI * 2 * Math.min(1, value));
      ctx.stroke();
    }
  }
}
