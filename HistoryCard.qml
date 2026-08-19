pragma ComponentBehavior: Bound

import QtQuick
import qs.Commons
import qs.Ui
import "Model.js" as Model

BorderSurface {
  id: root

  required property var session
  property color foreground: Color.foreground
  property color accent: Color.accent
  property color urgent: Color.urgent
  property color dim: Qt.darker(foreground, 1.5)
  property string fontFamily: Style.font.family
  readonly property string outcome: String(root.session ? root.session.outcome || "" : "")
  readonly property color outcomeColor: root.outcome === "rewound" ? root.urgent : root.accent

  height: Style.space(66)
  radius: Style.cornerRadius
  color: Style.normalFillFor(root.foreground, root.accent)
  borderSpec: Border.controlSpec("normal", root.foreground, root.accent)

  Rectangle {
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    width: Math.max(2, Style.space(3))
    height: parent.height - Style.space(20)
    radius: width / 2
    color: root.outcomeColor
  }

  Column {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    anchors.margins: Style.space(12)
    spacing: Style.space(3)

    Text {
      width: parent.width
      text: String(root.session ? root.session.label || "Omarchy experiment" : "")
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.body
      font.bold: true
      elide: Text.ElideRight
    }
    Text {
      width: parent.width
      text: Model.lastSessionMeta(root.session)
      color: root.outcomeColor
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: true
      font.letterSpacing: 1
    }
  }
}
