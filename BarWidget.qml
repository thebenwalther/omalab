pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

BarWidget {
  id: root
  moduleName: "com.omarchy.omarewind"

  property var manifest: null
  property var status: Model.emptyStatus()
  property bool refreshing: false
  property string lastStatusOutput: ""
  property string lastStatusError: ""
  property int lastStatusExitCode: -1

  // Omarchy's bar registry currently injects bar/settings/moduleName, but not
  // the plugin manifest. Resolve relative to this QML file so both a normal
  // clone and the development symlink locate the bundled command reliably.
  readonly property string commandPath: {
    if (manifest && manifest.__sourceDir) return manifest.__sourceDir + "/bin/omarewind"
    var url = String(Qt.resolvedUrl("bin/omarewind"))
    return decodeURIComponent(url.replace(/^file:\/\//, ""))
  }
  readonly property bool fearless: status && status.active === true
  readonly property int changeCount: status ? Number(status.totalChanges) || 0 : 0
  readonly property bool statusError: lastStatusExitCode > 0
  readonly property int activePollMs: Math.max(2, Math.min(60, Number(setting("activePollSeconds", 5)) || 5)) * 1000
  readonly property int idlePollMs: Math.max(10, Math.min(300, Number(setting("idlePollSeconds", 30)) || 30)) * 1000

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    target.bar = root.bar
    target.settings = root.settings
    target.anchorItem = button
    target.hostWidget = root
    target.commandPath = root.commandPath
    target.status = root.status
    target.backendError = root.statusError
    target.backendErrorText = root.lastStatusError
  }

  function adoptStatus(next) {
    root.status = next || Model.emptyStatus()
    injectPanel()
  }

  function refresh() {
    if (root.commandPath === "" || statusProc.running) return
    root.refreshing = true
    root.lastStatusOutput = ""
    root.lastStatusError = ""
    root.lastStatusExitCode = -1
    statusProc.command = [root.commandPath, "status"]
    statusProc.running = true
  }

  function open() {
    if (panelLoader.item) panelLoader.item.open()
  }

  function close() {
    if (panelLoader.item) panelLoader.item.close()
  }

  function togglePanel() {
    if (panelLoader.item) panelLoader.item.toggle()
  }

  function startFearlessMode() {
    if (!panelLoader.item) return "panel-unavailable"
    panelLoader.item.beginAction("start")
    return "ok"
  }

  function keepExperiment() {
    if (!panelLoader.item) return "panel-unavailable"
    panelLoader.item.requestKeep()
    return "ok"
  }

  function rewindExperiment() {
    if (!panelLoader.item) return "panel-unavailable"
    panelLoader.item.requestRewind()
    return "ok"
  }

  function undoRewind() {
    if (!panelLoader.item) return "panel-unavailable"
    panelLoader.item.requestUndo()
    return "ok"
  }

  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

  function closeForPopoutSwitch() {
    if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()
  onManifestChanged: {
    injectPanel()
    Qt.callLater(refresh)
  }

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  Process {
    id: statusProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.lastStatusOutput = String(text || "")
        // Preserve the last-good state if a transient probe fails. An empty
        // response must never make an active checkpoint look inactive.
        if (root.lastStatusOutput.trim() !== "")
          root.adoptStatus(Model.parseStatus(root.lastStatusOutput))
      }
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.lastStatusError = String(text || "")
    }
    onExited: function(exitCode) {
      root.lastStatusExitCode = exitCode
      root.refreshing = false
      root.injectPanel()
    }
  }

  Timer {
    interval: root.fearless ? root.activePollMs : root.idlePollMs
    repeat: true
    running: root.commandPath !== ""
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  IpcHandler {
    target: root.moduleName

    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.togglePanel() }
    function refresh(): string { root.broadcast("refresh"); return "ok" }
    function status(): string { return JSON.stringify(root.status) }
    function start(): string { return root.startFearlessMode() }
    function keep(): string { return root.keepExperiment() }
    function rewind(): string { return root.rewindExperiment() }
    function undo(): string { return root.undoRewind() }
    function debug(): string {
      return JSON.stringify({
        commandPath: root.commandPath,
        panelLoaded: panelLoader.item !== null,
        panelCommandPath: panelLoader.item ? panelLoader.item.effectiveCommandPath : "",
        statusProcessRunning: statusProc.running,
        refreshing: root.refreshing,
        lastStatusExitCode: root.lastStatusExitCode,
        lastStatusOutput: root.lastStatusOutput,
        lastStatusError: root.lastStatusError
      })
    }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.vertical
      ? "\uf0c3"
      : (root.fearless ? "FEARLESS · " + root.changeCount : "\uf1da")
    fontSize: root.fearless && !root.vertical ? Style.font.caption : Style.font.icon
    active: root.fearless
    activeColor: root.bar ? root.bar.barForeground : Color.foreground
    tooltipText: root.statusError ? "OmaRewind · Checkpoint needs attention" : Model.tooltip(root.status)
    horizontalMargin: root.fearless ? 10 : 8.5

    SequentialAnimation on opacity {
      running: root.fearless && root.changeCount === 0
      loops: Animation.Infinite
      NumberAnimation { to: 0.55; duration: 900; easing.type: Easing.InOutSine }
      NumberAnimation { to: 1.0; duration: 900; easing.type: Easing.InOutSine }
    }

    onPressed: function(buttonCode) {
      if (buttonCode === Qt.MiddleButton) root.refresh()
      else root.togglePanel()
    }
  }
}
