import 'package:hive/hive.dart';

part 'learning_input.g.dart';

/// Learning Input types
enum InputType { book, podcast, video, blog, course }

/// Status of the learning input
enum InputStatus { notStarted, inProgress, completed, archived }

/// Model for tracking learning inputs (books, podcasts, videos, etc.)
@HiveType(typeId: 5)
class LearningInput extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String type; // book, podcast, video, blog, course

  @HiveField(3)
  String source; // YouTube, Spotify, Web, Kindle, etc.

  @HiveField(4)
  String status; // not_started, in_progress, completed

  @HiveField(5)
  List<String> tags; // tech, philosophy, business, etc.

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime? completedAt;

  @HiveField(8)
  String? linkedTaskId; // Link to a task for time tracking

  @HiveField(9)
  String? notes;

  @HiveField(10)
  int estimatedMinutes; // Estimated time to complete

  @HiveField(11)
  String? url; // Link to the content

  @HiveField(12)
  String? description; // "Why I saved this"

  @HiveField(13, defaultValue: [])
  List<String> relatedIds;

  @HiveField(14, defaultValue: 'list')
  String displayMode; // 'list' or 'tree' - per-note display preference

  LearningInput({
    required this.id,
    required this.title,
    required this.type,
    required this.source,
    this.status = 'saved', // Default changed to 'saved' (maps to not_started)
    this.tags = const [],
    required this.createdAt,
    this.completedAt,
    this.linkedTaskId,
    this.notes,
    this.estimatedMinutes = 0,
    this.url,
    this.description,
    this.relatedIds = const [],
    this.displayMode = 'list', // Default to list view
  });

  // Helper getters
  InputType get inputType {
    switch (type.toLowerCase()) {
      case 'book':
        return InputType.book;
      case 'podcast':
        return InputType.podcast;
      case 'video':
        return InputType.video;
      case 'blog':
        return InputType.blog;
      case 'course':
        return InputType.course;
      default:
        return InputType.book;
    }
  }

  InputStatus get inputStatus {
    switch (status.toLowerCase()) {
      case 'saved':
      case 'not_started':
        return InputStatus.notStarted;
      case 'in_progress':
        return InputStatus.inProgress;
      case 'finished':
      case 'completed':
        return InputStatus.completed;
      case 'archived':
        return InputStatus.archived;
      default:
        return InputStatus.notStarted;
    }
  }

  bool get isCompleted => status == 'completed' || status == 'finished';
  bool get isInProgress => status == 'in_progress';
  bool get isSaved => status == 'saved' || status == 'not_started';
  bool get isArchived => status == 'archived';

  // Days since created
  int get daysSinceCreated => DateTime.now().difference(createdAt).inDays;
}
