pragma ComponentBehavior: Bound

import QtQuick
import qs.Commons
import qs.Ui
import "Model.js" as Model

CursorSurface {
  id: root

  required property var change
  property bool selected: false
  property color dim: Qt.darker(foreground, 1.5)
  property color urgent: Color.urgent
  property string fontFamily: Style.font.family

  signal previewRequested(string path)

  height: Style.space(28)
  current: selected
  hasCursor: pointer.containsMouse

  Text {
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    width: Style.space(78)
    text: Model.changeVerb(root.change.kind)
    color: root.change.kind === "deleted" ? root.urgent : root.dim
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption
    font.bold: true
  }
  Text {
    anchors.left: parent.left
    anchors.leftMargin: Style.space(84)
    anchors.right: parent.right
    anchors.rightMargin: Style.space(18)
    anchors.verticalCenter: parent.verticalCenter
    text: Model.compactPath(root.change.path)
    color: root.foreground
    font.family: root.fontFamily
    font.pixelSize: Style.font.bodySmall
    elide: Text.ElideLeft
  }
  Text {
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    text: root.selected ? "\uf078" : "\uf054"
    color: root.selected ? root.accent : root.dim
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption
  }

  MouseArea {
    id: pointer
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.previewRequested(String(root.change.path || ""))
  }
}
