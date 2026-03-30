import 'package:hive/hive.dart';

part 'time_entry.g.dart';

@HiveType(typeId: 1)
class TimeEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String taskId;

  @HiveField(2)
  final DateTime startTime;

  @HiveField(3)
  DateTime? endTime;

  @HiveField(4)
  String? note;

  TimeEntry({
    required this.id,
    required this.taskId,
    required this.startTime,
    this.endTime,
    this.note,
  });

  bool get isActive => endTime == null;

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }
}
