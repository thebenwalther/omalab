.pragma library

function emptyStatus() {
  return {
    active: false,
    totalChanges: 0,
    historyCount: 0,
    files: { added: 0, modified: 0, deleted: 0, total: 0 },
    packages: { added: 0, removed: 0, total: 0 },
    plugins: { added: 0, removed: 0, total: 0 },
    changes: []
  }
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
  if (value < 3600) return Math.floor(value / 60) + " MINUTES"
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

function tooltip(status) {
  if (!status || !status.active) return "OmaRewind · Start Fearless Mode"
  var count = Number(status.totalChanges) || 0
  return "Fearless Mode · " + plural(count, "change").toLowerCase()
}
