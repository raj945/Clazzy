import 'package:hive/hive.dart';

part 'deadline_item.g.dart';

@HiveType(typeId: 6)
class DeadlineItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  DateTime dueDate;

  @HiveField(3)
  String taskCategoryId; // task ID linking to activity category

  @HiveField(4)
  String status; // 'todo', 'in_progress', 'completed'

  @HiveField(5)
  int? estimatedMinutes;

  @HiveField(6)
  String? notes;

  DeadlineItem({
    required this.id,
    required this.title,
    required this.dueDate,
    required this.taskCategoryId,
    this.status = 'todo',
    this.estimatedMinutes,
    this.notes,
  });
}
