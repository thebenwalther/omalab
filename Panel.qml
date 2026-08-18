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
  property bool undoArmed: false
  property bool backendError: false
  property string backendErrorText: ""

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
    undoArmed = false
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
    var command = []
    if (action === "start") {
      var label = String(experimentNameField.text || "").trim()
      command = [root.effectiveCommandPath, "start", label !== "" ? label : "Omarchy experiment"]
    } else if (action === "keep") command = [root.effectiveCommandPath, "keep", "--yes"]
    else if (action === "rewind") command = [root.effectiveCommandPath, "rewind", "--yes"]
    else if (action === "undo") command = [root.effectiveCommandPath, "undo", "--yes"]
    else {
      root.resultText = "Unknown OmaRewind action."
      return
    }
    activeAction = action
    resultText = ""
    busy = true
    actionProc.command = command
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

  function requestUndo() {
    if (!root.status.canUndo) return
    if (!undoArmed) {
      undoArmed = true
      keepArmed = false
      rewindArmed = false
      armTimer.restart()
      return
    }
    undoArmed = false
    beginAction("undo")
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
    if (String(raw || "").trim() === "") return
    var next = Model.parseStatus(raw)
    if (hostWidget) hostWidget.adoptStatus(next)
    status = next
  }

  onStatusChanged: {
    if (!fearless) {
      rewindArmed = false
      keepArmed = false
    } else {
      undoArmed = false
      experimentNameField.text = ""
    }
  }

  Timer {
    id: armTimer
    interval: 5000
    onTriggered: {
      root.rewindArmed = false
      root.keepArmed = false
      root.undoArmed = false
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
      blocked: root.busy || experimentNameField.activeFocus
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onActivateRequested: if (!root.fearless) root.beginAction("start")
      onTextKey: function(text) {
        var key = String(text).toLowerCase()
        if (key === "s" && !root.fearless) root.beginAction("start")
        else if (key === "k" && root.fearless) root.requestKeep()
        else if (key === "r" && root.fearless) root.requestRewind()
        else if (key === "u" && !root.fearless && root.status.canUndo) root.requestUndo()
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
            title: root.fearless ? String(root.status.label || "Fearless Mode") : "Ready to experiment"
            meta: root.fearless
              ? "FEARLESS MODE · " + Model.formatElapsed(root.status.elapsedSeconds) + " · " + String(root.status.theme || "CURRENT THEME")
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

          BorderSurface {
            visible: root.backendError || root.resultText !== ""
            width: parent.width
            implicitHeight: backendErrorColumn.implicitHeight + Style.space(20)
            radius: Style.cornerRadius
            color: Style.normalFillFor(root.urgent, root.accent)
            borderSpec: Border.controlSpec("selected", root.urgent, root.accent)

            Column {
              id: backendErrorColumn
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              anchors.margins: Style.space(10)
              spacing: Style.space(3)

              Text {
                width: parent.width
                text: root.backendError ? "CHECKPOINT NEEDS ATTENTION" : "ACTION COULD NOT FINISH"
                color: root.urgent
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                font.bold: true
                font.letterSpacing: 1
              }
              Text {
                width: parent.width
                text: {
                  var message = root.resultText !== "" ? root.resultText : String(root.backendErrorText || "Status refresh failed")
                  return message.replace(/^OmaRewind:\s*/, "").trim()
                }
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
                wrapMode: Text.WordWrap
              }
              Button {
                visible: root.backendError
                text: root.hostWidget && root.hostWidget.refreshing ? "Checking…" : "Retry Check"
                iconText: "\uf021"
                bordered: true
                foreground: root.foreground
                accent: root.accent
                enabled: root.hostWidget && !root.hostWidget.refreshing
                onClicked: if (root.hostWidget) root.hostWidget.refresh()
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
              enabled: !root.busy && !root.backendError
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
              enabled: !root.busy && !root.backendError
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

          TextField {
            id: experimentNameField
            visible: !root.fearless
            width: parent.width
            placeholderText: "Name this experiment (optional)"
            foreground: root.foreground
            font.family: root.fontFamily
            maximumLength: 60
            enabled: !root.busy && !root.backendError

            Keys.onPressed: function(event) {
              if (event.key === Qt.Key_Escape) {
                experimentNameField.focus = false
                keyCatcher.forceActiveFocus()
                event.accepted = true
              }
            }
            onAccepted: root.beginAction("start")
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
            enabled: !root.busy && !root.backendError && root.effectiveCommandPath !== ""
            onClicked: root.beginAction("start")
          }

          Column {
            visible: !root.fearless && root.status.lastSession
            width: parent.width
            spacing: Style.space(8)

            PanelSeparator { foreground: root.foreground }
            PanelSectionHeader {
              text: "LAST EXPERIMENT"
              foreground: root.foreground
              fontFamily: root.fontFamily
            }

            BorderSurface {
              width: parent.width
              height: Style.space(66)
              radius: Style.cornerRadius
              color: Style.normalFillFor(root.foreground, root.accent)
              borderSpec: Border.controlSpec("normal", root.foreground, root.accent)

              Column {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Style.space(12)
                spacing: Style.space(3)

                Text {
                  width: parent.width
                  text: String(root.status.lastSession ? root.status.lastSession.label || "Omarchy experiment" : "")
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                  font.bold: true
                  elide: Text.ElideRight
                }
                Text {
                  width: parent.width
                  text: Model.lastSessionMeta(root.status.lastSession)
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                  font.letterSpacing: 1
                }
              }
            }

            Text {
              visible: root.status.canUndo === true
              width: parent.width
              text: "Changed your mind? The experiment was preserved before its configs were restored."
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              wrapMode: Text.WordWrap
            }

            Button {
              visible: root.status.canUndo === true
              width: parent.width
              text: root.undoArmed ? "Click again to restore experiment" : (root.busy && root.activeAction === "undo" ? "Restoring experiment…" : "Undo Last Rewind")
              iconText: "\uf2ea"
              bordered: true
              selected: root.undoArmed
              foreground: root.undoArmed ? root.urgent : root.foreground
              accent: root.undoArmed ? root.urgent : root.accent
              enabled: !root.busy && !root.backendError
              onClicked: root.requestUndo()
            }
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

          BorderSurface {
            visible: root.fearless && root.status.packages && root.status.packages.total > 0
            width: parent.width
            implicitHeight: packageWarningColumn.implicitHeight + Style.space(20)
            radius: Style.cornerRadius
            color: Style.normalFillFor(root.urgent, root.accent)
            borderSpec: Border.controlSpec("normal", root.urgent, root.accent)

            Column {
              id: packageWarningColumn
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              anchors.margins: Style.space(10)
              spacing: Style.space(3)

              Text {
                width: parent.width
                text: "PACKAGE CHANGES STAY IN PLACE"
                color: root.urgent
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                font.bold: true
                font.letterSpacing: 1
              }
              Text {
                width: parent.width
                text: "Config rewind never installs or removes packages. Use the system checkpoint for a complete machine rollback."
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
                wrapMode: Text.WordWrap
              }
              Text {
                visible: Model.changedNames(root.status.packages) !== ""
                width: parent.width
                text: Model.changedNames(root.status.packages)
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                elide: Text.ElideRight
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
            width: parent.width
            text: root.status.canUndo
              ? "S start  ·  U undo rewind  ·  Esc close"
              : "S start  ·  K keep  ·  R rewind  ·  Esc close"
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
