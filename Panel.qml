pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root
  moduleName: "com.omarchy.omarewind"
  ipcTarget: root.moduleName
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property string commandPath: ""
  property var status: Model.emptyStatus()
  property bool busy: false
  property string activeAction: ""
  property string resultText: ""
  property bool rewindArmed: false
  property bool keepArmed: false

  readonly property string effectiveCommandPath: root.commandPath !== ""
    ? root.commandPath
    : (root.hostWidget ? root.hostWidget.commandPath : "")

  readonly property bool fearless: status && status.active === true
  readonly property color foreground: root.bar ? root.bar.foreground : Color.foreground
  readonly property color urgent: root.bar ? root.bar.urgent : Color.urgent
  readonly property color accent: Color.accent
  readonly property color dim: Qt.darker(foreground, 1.5)
  readonly property string fontFamily: root.bar ? root.bar.fontFamily : Style.font.family

  function open() {
    if (hostWidget) hostWidget.refresh()
    root.controller.show()
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  function close() {
    rewindArmed = false
    keepArmed = false
    root.controller.hide()
  }

  function toggle() {
    root.opened ? root.close() : root.open()
  }

  function beginAction(action) {
    if (root.busy || root.effectiveCommandPath === "") {
      root.resultText = "OmaRewind could not locate its checkpoint command."
      return
    }
    activeAction = action
    resultText = ""
    busy = true
    if (action === "start") actionProc.command = [root.effectiveCommandPath, "start", "Omarchy experiment"]
    else if (action === "keep") actionProc.command = [root.effectiveCommandPath, "keep", "--yes"]
    else if (action === "rewind") actionProc.command = [root.effectiveCommandPath, "rewind", "--yes"]
    else return
    actionProc.running = true
  }

  function requestKeep() {
    if (!keepArmed) {
      keepArmed = true
      rewindArmed = false
      armTimer.restart()
      return
    }
    keepArmed = false
    beginAction("keep")
  }

  function requestRewind() {
    if (!rewindArmed) {
      rewindArmed = true
      keepArmed = false
      armTimer.restart()
      return
    }
    rewindArmed = false
    beginAction("rewind")
  }

  function createSystemSnapshot() {
    if (root.bar) root.bar.run("omarchy-launch-floating-terminal-with-presentation omarchy snapshot create")
  }

  function metricModel() {
    return [
      { label: "FILES", value: status.files ? status.files.total : 0, detail: fileDetail() },
      { label: "PACKAGES", value: status.packages ? status.packages.total : 0, detail: listDetail(status.packages) },
      { label: "PLUGINS", value: status.plugins ? status.plugins.total : 0, detail: listDetail(status.plugins) }
    ]
  }

  function fileDetail() {
    if (!status.files) return "NO CHANGES"
    var bits = []
    if (status.files.added) bits.push("+" + status.files.added)
    if (status.files.modified) bits.push("~" + status.files.modified)
    if (status.files.deleted) bits.push("−" + status.files.deleted)
    return bits.length > 0 ? bits.join("  ") : "NO CHANGES"
  }

  function listDetail(value) {
    if (!value) return "NO CHANGES"
    var bits = []
    if (value.added) bits.push("+" + value.added)
    if (value.removed) bits.push("−" + value.removed)
    return bits.length > 0 ? bits.join("  ") : "NO CHANGES"
  }

  function adoptActionOutput(raw) {
    var next = Model.parseStatus(raw)
    if (hostWidget) hostWidget.adoptStatus(next)
    status = next
  }

  onStatusChanged: {
    if (!fearless) {
      rewindArmed = false
      keepArmed = false
    }
  }

  Timer {
    id: armTimer
    interval: 5000
    onTriggered: {
      root.rewindArmed = false
      root.keepArmed = false
    }
  }

  Process {
    id: actionProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.adoptActionOutput(text)
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var message = String(text || "").trim()
        if (message !== "") root.resultText = message.replace(/^OmaRewind:\s*/, "")
      }
    }
    onExited: function(exitCode) {
      root.busy = false
      if (exitCode !== 0 && root.resultText === "") root.resultText = "The action could not be completed."
      if (root.hostWidget) Qt.callLater(root.hostWidget.refresh)
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    centerOnBar: true
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(500))
    contentHeight: panel.fittedContentHeight(contentColumn.implicitHeight, Style.space(650))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      blocked: root.busy
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onActivateRequested: if (!root.fearless) root.beginAction("start")
      onTextKey: function(text) {
        var key = String(text).toLowerCase()
        if (key === "s" && !root.fearless) root.beginAction("start")
        else if (key === "k" && root.fearless) root.requestKeep()
        else if (key === "r" && root.fearless) root.requestRewind()
      }

      Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: contentColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
          id: contentColumn
          width: parent.width
          spacing: Style.spacing.panelGap

          PanelHero {
            width: parent.width
            foreground: root.foreground
            fontFamily: root.fontFamily
            title: root.fearless ? "Fearless Mode" : "Ready to experiment"
            meta: root.fearless
              ? Model.formatElapsed(root.status.elapsedSeconds) + " · " + String(root.status.theme || "CURRENT THEME")
              : "OMA REWIND IS STANDING BY"
            detail: root.fearless ? Model.plural(root.status.totalChanges, "CHANGE") : "SAFE"
            iconComponent: Component {
              Item {
                implicitWidth: Style.space(48)
                implicitHeight: Style.space(48)

                BorderSurface {
                  anchors.fill: parent
                  radius: width / 2
                  color: root.fearless
                    ? Style.selectedFillFor(root.foreground, root.accent)
                    : Style.normalFillFor(root.foreground, root.accent)
                  borderSpec: Border.controlSpec(root.fearless ? "selected" : "normal", root.foreground, root.accent)

                  Text {
                    anchors.centerIn: parent
                    text: "\uf0c3"
                    color: root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.display
                  }
                }
              }
            }
          }

          Row {
            id: actionRow
            visible: root.fearless
            width: parent.width
            spacing: Style.space(8)

            Button {
              width: (actionRow.width - actionRow.spacing) / 2
              text: root.keepArmed ? "Click again to keep" : (root.busy && root.activeAction === "keep" ? "Keeping…" : "Keep Changes")
              iconText: "\uf00c"
              bordered: true
              foreground: root.foreground
              accent: root.accent
              enabled: !root.busy
              onClicked: root.requestKeep()
            }

            Button {
              width: (actionRow.width - actionRow.spacing) / 2
              text: root.rewindArmed ? "Click again to rewind" : (root.busy && root.activeAction === "rewind" ? "Rewinding…" : "Rewind Configs")
              iconText: "\uf1da"
              bordered: true
              selected: root.rewindArmed
              foreground: root.rewindArmed ? root.urgent : root.foreground
              accent: root.rewindArmed ? root.urgent : root.accent
              enabled: !root.busy
              onClicked: root.requestRewind()
            }
          }

          Text {
            visible: !root.fearless
            width: parent.width
            text: "Capture your Omarchy setup, try something bold, then keep it or return to exactly where you started."
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            wrapMode: Text.WordWrap
            lineHeight: 1.25
          }

          Button {
            visible: !root.fearless
            width: parent.width
            text: root.busy && root.activeAction === "start" ? "Creating checkpoint…" : "Start Fearless Mode"
            iconText: "\uf0c3"
            selected: true
            bordered: true
            foreground: root.foreground
            accent: root.accent
            enabled: !root.busy && root.effectiveCommandPath !== ""
            onClicked: root.beginAction("start")
          }

          Column {
            visible: root.fearless
            width: parent.width
            spacing: Style.space(8)

            PanelSectionHeader {
              text: "SINCE YOUR CHECKPOINT"
              foreground: root.foreground
              fontFamily: root.fontFamily
            }

            Row {
              id: metricsRow
              width: parent.width
              spacing: Style.space(8)

              Repeater {
                model: root.metricModel()

                BorderSurface {
                  id: metricCard
                  required property var modelData
                  width: (metricsRow.width - metricsRow.spacing * 2) / 3
                  height: Style.space(82)
                  radius: Style.cornerRadius
                  color: Style.normalFillFor(root.foreground, root.accent)
                  borderSpec: Border.controlSpec("normal", root.foreground, root.accent)

                  Column {
                    anchors.centerIn: parent
                    spacing: Style.space(2)

                    Text {
                      anchors.horizontalCenter: parent.horizontalCenter
                      text: String(metricCard.modelData.value)
                      color: root.foreground
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.display
                      font.bold: true
                    }
                    Text {
                      anchors.horizontalCenter: parent.horizontalCenter
                      text: metricCard.modelData.label
                      color: root.dim
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      font.bold: true
                      font.letterSpacing: 1
                    }
                    Text {
                      anchors.horizontalCenter: parent.horizontalCenter
                      text: metricCard.modelData.detail
                      color: root.dim
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                    }
                  }
                }
              }
            }
          }

          Column {
            visible: root.fearless && root.status.changes && root.status.changes.length > 0
            width: parent.width
            spacing: Style.space(2)

            PanelSeparator { foreground: root.foreground }
            PanelSectionHeader {
              text: "RECENT CONFIGURATION CHANGES"
              foreground: root.foreground
              fontFamily: root.fontFamily
            }

            Repeater {
              model: root.status.changes || []

              Item {
                id: changeRow
                required property var modelData
                width: parent.width
                height: Style.space(28)

                Text {
                  anchors.left: parent.left
                  anchors.verticalCenter: parent.verticalCenter
                  width: Style.space(78)
                  text: Model.changeVerb(changeRow.modelData.kind)
                  color: changeRow.modelData.kind === "deleted" ? root.urgent : root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                }
                Text {
                  anchors.left: parent.left
                  anchors.leftMargin: Style.space(84)
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  text: Model.compactPath(changeRow.modelData.path)
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  elide: Text.ElideLeft
                }
              }
            }
          }

          Text {
            visible: root.fearless && root.status.totalChanges === 0
            width: parent.width
            text: "Your checkpoint is clean. Go make something interesting."
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            horizontalAlignment: Text.AlignHCenter
          }

          PanelSeparator { foreground: root.foreground }

          Row {
            width: parent.width
            spacing: Style.space(12)

            Column {
              width: parent.width - systemSnapshotButton.width - parent.spacing
              spacing: Style.space(2)
              Text {
                width: parent.width
                text: "SYSTEM CHECKPOINT"
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                font.bold: true
                font.letterSpacing: 1
              }
              Text {
                width: parent.width
                text: "Optional root snapshot for package and kernel experiments. Opens the official Omarchy command in a terminal."
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
                wrapMode: Text.WordWrap
              }
            }

            Button {
              id: systemSnapshotButton
              anchors.verticalCenter: parent.verticalCenter
              text: "Create"
              iconText: "\uf1da"
              bordered: true
              foreground: root.foreground
              accent: root.accent
              onClicked: root.createSystemSnapshot()
            }
          }

          Text {
            visible: root.resultText !== ""
            width: parent.width
            text: root.resultText
            color: root.urgent
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            wrapMode: Text.WordWrap
          }

          Text {
            width: parent.width
            text: "S start  ·  K keep  ·  R rewind  ·  Esc close"
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            horizontalAlignment: Text.AlignHCenter
          }
        }
      }
    }
  }
}
