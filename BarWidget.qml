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

  readonly property string commandPath: manifest && manifest.__sourceDir
    ? manifest.__sourceDir + "/bin/omarewind"
    : ""
  readonly property bool fearless: status && status.active === true
  readonly property int changeCount: status ? Number(status.totalChanges) || 0 : 0

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    target.bar = root.bar
    target.settings = root.settings
    target.anchorItem = button
    target.hostWidget = root
    target.commandPath = root.commandPath
    target.status = root.status
  }

  function adoptStatus(next) {
    root.status = next || Model.emptyStatus()
    injectPanel()
  }

  function refresh() {
    if (root.commandPath === "" || statusProc.running) return
    root.refreshing = true
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
      onStreamFinished: root.adoptStatus(Model.parseStatus(text))
    }
    onExited: root.refreshing = false
  }

  Timer {
    interval: root.fearless ? 5000 : 30000
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
    tooltipText: Model.tooltip(root.status)
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
