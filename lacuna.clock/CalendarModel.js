.pragma library

function localNoon(year, month, day) {
  return new Date(Number(year), Number(month), Number(day), 12, 0, 0, 0)
}

function normalizedDate(value) {
  var date = value instanceof Date ? value : new Date(value)
  return localNoon(date.getFullYear(), date.getMonth(), date.getDate())
}

function dateKey(value) {
  var date = normalizedDate(value)
  var month = date.getMonth() + 1
  var day = date.getDate()
  return date.getFullYear() + "-" + (month < 10 ? "0" : "") + month + "-" + (day < 10 ? "0" : "") + day
}

function sameDay(left, right) {
  if (!(left instanceof Date) || !(right instanceof Date)) return false
  return dateKey(left) === dateKey(right)
}

function sameMonth(left, right) {
  if (!(left instanceof Date) || !(right instanceof Date)) return false
  return left.getFullYear() === right.getFullYear() && left.getMonth() === right.getMonth()
}

function monthStart(value) {
  var date = normalizedDate(value)
  return localNoon(date.getFullYear(), date.getMonth(), 1)
}

function shiftedMonth(value, amount) {
  var date = monthStart(value)
  return localNoon(date.getFullYear(), date.getMonth() + Number(amount || 0), 1)
}

function monthCells(year, month) {
  var first = localNoon(year, month, 1)
  var start = localNoon(first.getFullYear(), first.getMonth(), 1 - first.getDay())
  var result = []
  for (var index = 0; index < 42; index++) {
    var date = localNoon(start.getFullYear(), start.getMonth(), start.getDate() + index)
    result.push({
      date: date,
      key: dateKey(date),
      year: date.getFullYear(),
      month: date.getMonth(),
      day: date.getDate(),
      inMonth: date.getFullYear() === first.getFullYear() && date.getMonth() === first.getMonth()
    })
  }
  return result
}

function weekdayLabels(locale) {
  var sunday = localNoon(2026, 0, 4)
  var result = []
  for (var index = 0; index < 7; index++) {
    var date = localNoon(sunday.getFullYear(), sunday.getMonth(), sunday.getDate() + index)
    result.push(locale.toString(date, "ddd"))
  }
  return result
}
