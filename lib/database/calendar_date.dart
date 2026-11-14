DateTime calendarDate(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

String calendarDateText(DateTime date) {
  final normalized = calendarDate(date);
  return '${normalized.year.toString().padLeft(4, '0')}-'
      '${normalized.month.toString().padLeft(2, '0')}-'
      '${normalized.day.toString().padLeft(2, '0')}';
}

String localTodayText() {
  return calendarDateText(DateTime.now());
}
