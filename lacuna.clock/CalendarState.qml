import QtQuick
import "CalendarModel.js" as CalendarModel

QtObject {
  id: root

  property date liveDate: new Date()
  property date selectedDate: new Date(0)
  property date viewedMonth: new Date(0)
  property date previousLiveDate: new Date(0)
  property bool initialized: false

  readonly property var cells: CalendarModel.monthCells(viewedMonth.getFullYear(), viewedMonth.getMonth())
  readonly property var weekdayLabels: CalendarModel.weekdayLabels(Qt.locale())
  readonly property string selectedKey: CalendarModel.dateKey(selectedDate)
  readonly property string todayKey: CalendarModel.dateKey(liveDate)

  function showPreviousMonth() {
    viewedMonth = CalendarModel.shiftedMonth(viewedMonth, -1)
  }

  function showNextMonth() {
    viewedMonth = CalendarModel.shiftedMonth(viewedMonth, 1)
  }

  function selectDate(value) {
    selectedDate = CalendarModel.normalizedDate(value)
    if (!CalendarModel.sameMonth(selectedDate, viewedMonth))
      viewedMonth = CalendarModel.monthStart(selectedDate)
  }

  function selectCell(cell) {
    if (cell && cell.date) selectDate(cell.date)
  }

  function showToday() {
    selectedDate = CalendarModel.normalizedDate(liveDate)
    viewedMonth = CalendarModel.monthStart(liveDate)
  }

  function syncLiveDate(value) {
    var next = CalendarModel.normalizedDate(value)
    var wasFollowingToday = CalendarModel.sameDay(selectedDate, previousLiveDate)
      && CalendarModel.sameMonth(viewedMonth, previousLiveDate)
    if (!CalendarModel.sameDay(next, previousLiveDate) && wasFollowingToday) {
      selectedDate = next
      viewedMonth = CalendarModel.monthStart(next)
    }
    previousLiveDate = next
  }

  Component.onCompleted: {
    selectedDate = CalendarModel.normalizedDate(liveDate)
    viewedMonth = CalendarModel.monthStart(liveDate)
    previousLiveDate = CalendarModel.normalizedDate(liveDate)
    initialized = true
  }

  onLiveDateChanged: if (initialized) syncLiveDate(liveDate)
}
