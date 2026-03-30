import 'package:hive/hive.dart';

part 'goal.g.dart';

@HiveType(typeId: 3)
class Goal extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? taskId;

  @HiveField(3)
  final int targetMinutes; // Used for time-based goals

  @HiveField(4)
  final int colorValue;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final String contributionType; // 'time' or 'event'

  @HiveField(7)
  final int? targetCount; // Used for event-based goals

  @HiveField(8)
  final String? eventTitlePattern; // Pattern to match event titles (e.g., "DSA Class")

  Goal({
    required this.id,
    required this.name,
    this.taskId,
    required this.targetMinutes,
    required this.colorValue,
    required this.createdAt,
    this.contributionType = 'time',
    this.targetCount,
    this.eventTitlePattern,
  });

  String get description {
    if (contributionType == 'event') {
      if (eventTitlePattern != null && eventTitlePattern!.isNotEmpty) {
        return 'Track attendance for "$eventTitlePattern" events';
      }
      return 'Track event attendance';
    }
    if (taskId == null) {
      return 'Track ${targetMinutes}m of any activity daily';
    }
    return 'Track ${targetMinutes}m daily';
  }
}
