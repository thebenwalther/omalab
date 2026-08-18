.pragma library

function emptyStatus() {
  return {
    active: false,
    totalChanges: 0,
    historyCount: 0,
    canUndo: false,
    lastSession: null,
    recentHistory: [],
    files: { added: 0, modified: 0, deleted: 0, total: 0 },
    packages: { added: 0, removed: 0, total: 0 },
    plugins: { added: 0, removed: 0, total: 0 },
    changes: []
  }
}

function recentSessions(status, limit) {
  if (!status) return []
  var sessions = status.recentHistory || []
  if (sessions.length === 0 && status.lastSession) sessions = [status.lastSession]
  return sessions.slice(0, Math.max(0, Number(limit) || 0))
}

function parseStatus(raw) {
  var text = String(raw || "").trim()
  if (text === "") return emptyStatus()
  try {
    var value = JSON.parse(text)
    return value && typeof value === "object" ? value : emptyStatus()
  } catch (error) {
    return emptyStatus()
  }
}

function formatElapsed(seconds) {
  var value = Math.max(0, Number(seconds) || 0)
  if (value < 60) return "JUST STARTED"
  if (value < 3600) {
    var wholeMinutes = Math.floor(value / 60)
    return wholeMinutes + (wholeMinutes === 1 ? " MINUTE" : " MINUTES")
  }
  if (value < 86400) {
    var hours = Math.floor(value / 3600)
    var minutes = Math.floor((value % 3600) / 60)
    return hours + "H" + (minutes > 0 ? " " + minutes + "M" : "")
  }
  var days = Math.floor(value / 86400)
  var remainingHours = Math.floor((value % 86400) / 3600)
  return days + "D" + (remainingHours > 0 ? " " + remainingHours + "H" : "")
}

function plural(count, word) {
  var value = Number(count) || 0
  return value + " " + word + (value === 1 ? "" : "S")
}

function compactPath(path) {
  var value = String(path || "")
  if (value.indexOf(".config/") === 0) value = value.slice(8)
  return value.length > 44 ? "…" + value.slice(value.length - 43) : value
}

function changeVerb(kind) {
  if (kind === "added") return "ADDED"
  if (kind === "deleted") return "REMOVED"
  return "CHANGED"
}

function outcomeLabel(outcome) {
  if (outcome === "rewound") return "REWOUND"
  if (outcome === "rewind-undone") return "REWIND UNDONE"
  if (outcome === "kept") return "KEPT"
  return "COMPLETED"
}

function lastSessionMeta(session) {
  if (!session) return "NO COMPLETED EXPERIMENTS"
  var bits = [outcomeLabel(String(session.outcome || ""))]
  if (session.finishedAt) {
    var date = new Date(String(session.finishedAt))
    if (!isNaN(date.getTime())) bits.push(date.toLocaleDateString(Qt.locale(), "MMM d"))
  }
  return bits.join(" · ")
}

function tooltip(status) {
  if (!status || !status.active) return "OmaRewind · Start Fearless Mode"
  var count = Number(status.totalChanges) || 0
  var label = String(status.label || "Fearless Mode")
  return label + " · " + plural(count, "change").toLowerCase()
}

function changedNames(value) {
  if (!value) return ""
  var names = []
  var added = value.addedNames || []
  var removed = value.removedNames || []
  for (var i = 0; i < added.length; i++) names.push("+" + added[i])
  for (var j = 0; j < removed.length; j++) names.push("−" + removed[j])
  if (names.length > 4) return names.slice(0, 4).join("  ") + "  +" + (names.length - 4) + " more"
  return names.join("  ")
}
