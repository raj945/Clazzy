import 'package:hive/hive.dart';

part 'scheduled_event.g.dart';

@HiveType(typeId: 2)
class ScheduledEvent extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  final DateTime startTime;

  @HiveField(4)
  final DateTime endTime;

  @HiveField(5)
  final int colorValue;

  @HiveField(6)
  final bool isAllDay;

  @HiveField(7)
  final String? linkedTaskId;

  @HiveField(8)
  final String recurrenceType; // 'none', 'daily', 'weekly'

  @HiveField(9)
  final DateTime? recurrenceEndTime;

  @HiveField(10)
  final List<int>? recurrenceDays; // 1=Mon, ..., 7=Sun

  @HiveField(11)
  final bool isCompleted;

  @HiveField(12)
  final List<DateTime>? completedDates; // For recurring events

  @HiveField(13)
  final List<DateTime>? excludedDates; // For recurring events exceptions

  ScheduledEvent({
    required this.id,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    required this.colorValue,
    this.isAllDay = false,
    this.linkedTaskId,
    this.recurrenceType = 'none',
    this.recurrenceEndTime,
    this.recurrenceDays,
    this.isCompleted = false,
    this.completedDates,
    this.excludedDates,
  });

  Duration get duration => endTime.difference(startTime);
}
