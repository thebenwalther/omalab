pragma ComponentBehavior: Bound

import QtQuick
import qs.Commons
import qs.Ui

BorderSurface {
  id: root

  property string path: ""
  // Item already owns a default `data` property for visual children. Using
  // that name for preview JSON steals the Column from the scene graph and
  // collapses the card to an empty strip.
  property var preview: null
  property bool busy: false
  property string error: ""
  property color foreground: Color.foreground
  property color accent: Color.accent
  property color dim: Qt.darker(foreground, 1.5)
  property color urgent: Color.urgent
  property string fontFamily: Style.font.family

  implicitHeight: content.implicitHeight + Style.space(20)
  radius: Style.cornerRadius
  color: Style.normalFillFor(root.foreground, root.accent)
  borderSpec: Border.controlSpec("normal", root.foreground, root.accent)

  Column {
    id: content
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    anchors.margins: Style.space(10)
    spacing: Style.space(6)

    Text {
      width: parent.width
      text: root.path
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: true
      elide: Text.ElideLeft
    }
    Text {
      visible: root.busy
      width: parent.width
      text: "Generating checkpoint diff…"
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
    }
    Text {
      visible: root.error !== ""
      width: parent.width
      text: root.error
      color: root.urgent
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WordWrap
    }
    Text {
      visible: root.preview && !root.busy
      width: parent.width
      text: root.preview ? String(root.preview.text || "") : ""
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      wrapMode: Text.WrapAnywhere
    }
    Text {
      visible: root.preview && root.preview.truncated === true
      width: parent.width
      text: "PREVIEW LIMITED TO 36 LINES / 16 KIB"
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: true
      font.letterSpacing: 1
    }
  }
}
