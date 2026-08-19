pragma ComponentBehavior: Bound

import QtQuick
import qs.Commons
import qs.Ui

BorderSurface {
  id: root

  required property var metric
  property color foreground: Color.foreground
  property color accent: Color.accent
  property color dim: Qt.darker(foreground, 1.5)
  property string fontFamily: Style.font.family
  readonly property bool highlighted: Number(root.metric.value) > 0

  height: Style.space(82)
  radius: Style.cornerRadius
  color: root.highlighted ? Util.alpha(root.accent, 0.12) : Style.normalFillFor(root.foreground, root.accent)
  borderSpec: root.highlighted
    ? Border.flat(Util.alpha(root.accent, 0.72), Math.max(1, Style.normalBorderWidth))
    : Border.controlSpec("normal", root.foreground, root.accent)

  Behavior on color { ColorAnimation { duration: 160 } }

  Column {
    anchors.centerIn: parent
    spacing: Style.space(2)

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: String(root.metric.value)
      color: root.highlighted ? root.accent : root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.display
      font.bold: true
    }
    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: String(root.metric.label || "")
      color: root.highlighted ? root.accent : root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: true
      font.letterSpacing: 1
    }
    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: String(root.metric.detail || "")
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
    }
  }
}
