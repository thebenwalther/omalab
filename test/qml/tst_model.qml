import QtQuick
import QtTest
import "../../Model.js" as Model

TestCase {
  name: "OmaLabModel"

  function test_emptyStatusIsSafe() {
    var status = Model.emptyStatus()
    compare(status.active, false)
    compare(status.totalChanges, 0)
    compare(status.canUndo, false)
    compare(status.changes.length, 0)
    compare(status.recentHistory.length, 0)
  }

  function test_recentSessions() {
    var first = {label: "Newest"}
    var second = {label: "Older"}
    compare(Model.recentSessions({recentHistory: [first, second]}, 1)[0].label, "Newest")
    compare(Model.recentSessions({recentHistory: [], lastSession: second}, 3)[0].label, "Older")
    compare(Model.recentSessions(null, 3).length, 0)
  }

  function test_parseStatusFallsBack() {
    compare(Model.parseStatus(""), null)
    compare(Model.parseStatus("not json"), null)
    compare(Model.parseStatus("null"), null)
    compare(Model.parseStatus("[]"), null)
    compare(Model.parseStatus("{}"), null)
    compare(Model.parseStatus('{"active":"true"}'), null)
    compare(Model.parseStatus('{"active":true,"totalChanges":2}').totalChanges, 2)
    compare(Model.parseStatus('{"active":false}').active, false)
    compare(Model.isStatus(Model.emptyStatus()), true)
    compare(Model.isStatus([]), false)
  }

  function test_elapsedFormatting() {
    compare(Model.formatElapsed(-5), "JUST STARTED")
    compare(Model.formatElapsed(59), "JUST STARTED")
    compare(Model.formatElapsed(60), "1 MINUTE")
    compare(Model.formatElapsed(120), "2 MINUTES")
    compare(Model.formatElapsed(3660), "1H 1M")
    compare(Model.formatElapsed(7200), "2H")
    compare(Model.formatElapsed(90000), "1D 1H")
  }

  function test_labelsAndPluralization() {
    compare(Model.plural(0, "CHANGE"), "0 CHANGES")
    compare(Model.plural(1, "CHANGE"), "1 CHANGE")
    compare(Model.changeVerb("added"), "ADDED")
    compare(Model.changeVerb("deleted"), "REMOVED")
    compare(Model.changeVerb("modified"), "CHANGED")
    compare(Model.outcomeLabel("rewind-undone"), "REWIND UNDONE")
  }

  function test_pathCompaction() {
    compare(Model.compactPath(".config/hypr/bindings.lua"), "hypr/bindings.lua")
    var compact = Model.compactPath(".config/omarchy/plugins/community.example/really/deep/component/Panel.qml")
    verify(compact.indexOf("…") === 0)
    compare(compact.length, 44)
  }

  function test_tooltips() {
    compare(Model.tooltip(null), "OmaLab · Start Fearless Mode")
    compare(Model.tooltip({active: true, label: "Theme test", totalChanges: 1}), "Theme test · 1 change")
    compare(Model.tooltip({active: true, totalChanges: 2}), "Fearless Mode · 2 changes")
  }

  function test_changedNamesAreBounded() {
    compare(Model.changedNames(null), "")
    compare(Model.changedNames({addedNames: ["one"], removedNames: ["two"]}), "+one  −two")
    compare(
      Model.changedNames({addedNames: ["a", "b", "c"], removedNames: ["d", "e", "f"]}),
      "+a  +b  +c  −d  +2 more"
    )
  }
}
