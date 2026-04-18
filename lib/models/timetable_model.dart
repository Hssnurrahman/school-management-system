class TimetableEntry {
  final String? id;
  final String day;
  final String startTime;
  final String endTime;
  final String subject;
  final String room;

  TimetableEntry({
    this.id,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.subject,
    required this.room,
  });
}
