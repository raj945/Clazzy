import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/task_node.dart';
import '../models/time_entry.dart';
import '../models/scheduled_event.dart';
import '../models/goal.dart';
import '../models/learning_input.dart';
import '../models/deadline_item.dart';
import '../constants/colors.dart';

class TimeTrackerProvider with ChangeNotifier {
  Box<TaskNode>? _taskBox;
  Box<TimeEntry>? _timeBox;
  Box<String>? _categoryBox; // Stores category -> baseType mapping
  Box<ScheduledEvent>? _eventBox;
  Box<Goal>? _goalBox;
  Box<LearningInput>? _learningInputBox;
  Box<DeadlineItem>? _deadlineBox;
  Box<String>? _learningCategoryBox; // Stores persistent custom categories

  List<TaskNode> _tasks = [];
  List<TimeEntry> _history = [];
  List<ScheduledEvent> _events = [];
  List<Goal> _goals = [];
  List<LearningInput> _learningInputs = [];
  List<String> _customLearningCategories = [];
  List<DeadlineItem> _deadlines = [];
  TimeEntry? _currentEntry;

  Timer? _ticker;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<TaskNode> get tasks => _tasks;
  List<TimeEntry> get history => _history;
  List<ScheduledEvent> get events => _events;
  List<Goal> get goals => _goals;
  List<LearningInput> get learningInputs => _learningInputs;
  List<DeadlineItem> get deadlines => _deadlines;
  TimeEntry? get currentEntry => _currentEntry;

  Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TaskNodeAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(TimeEntryAdapter());
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ScheduledEventAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(GoalAdapter());
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(LearningInputAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(DeadlineItemAdapter());
    }

    _taskBox = await Hive.openBox<TaskNode>('tasks');
    _timeBox = await Hive.openBox<TimeEntry>('time_entries');
    _categoryBox = await Hive.openBox<String>('categories');
    _eventBox = await Hive.openBox<ScheduledEvent>('events');
    _goalBox = await Hive.openBox<Goal>('goals');
    _learningInputBox = await Hive.openBox<LearningInput>('learning_inputs');
    _deadlineBox = await Hive.openBox<DeadlineItem>('deadlines');
    _learningCategoryBox = await Hive.openBox<String>('learning_categories');

    await _loadData();

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners();
    });

    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_taskBox == null || _timeBox == null) return;

    if (_taskBox!.isEmpty) {
      await _seedDefaultTasks();
    }
    if (_categoryBox!.isEmpty) {
      await _seedDefaultCategories();
    }
    _tasks = _taskBox!.values.toList();

    _history = _timeBox!.values.toList();
    _history.sort((a, b) => b.startTime.compareTo(a.startTime));

    _events = _eventBox!.values.toList();
    _events.sort((a, b) => a.startTime.compareTo(b.startTime));

    _customLearningCategories = _learningCategoryBox!.values.toList();

    _goals = _goalBox!.values.toList();
    _learningInputs = _learningInputBox!.values.toList();
    _learningInputs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    _deadlines = _deadlineBox!.values.toList();
    _deadlines.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    try {
      _currentEntry = _history.firstWhere((entry) => entry.isActive);
    } catch (e) {
      _currentEntry = null;
    }

    if (_currentEntry == null) {
      await _startUnknownTask();
    }
  }

  Future<void> _seedDefaultCategories() async {
    await _categoryBox!.put('LEARNING', 'DEEP WORK');
    await _categoryBox!.put('WORK', 'DEEP WORK');
    await _categoryBox!.put('HEALTH', 'PERSONAL');
    await _categoryBox!.put('MAINTENANCE', 'PERSONAL');
    await _categoryBox!.put('ENTERTAINMENT', 'WASTED');
    await _categoryBox!.put('REST', 'SLEEP');
  }

  Future<void> _seedDefaultTasks() async {
    final defaults = [
      TaskNode(
        id: TaskNode.unknownId,
        name: 'Unassigned Time',
        subtitle: 'Unknown',
        category: '',
        colorValue: AppColors.unknown.value,
        baseType: 'UNKNOWN',
      ),
      TaskNode(
        id: 'reading',
        name: 'Reading',
        subtitle: 'Technical',
        category: 'LEARNING',
        colorValue: const Color(0xFFFF9800).value, // Orange - Learning
        baseType: 'DEEP WORK',
      ),
      TaskNode(
        id: 'course',
        name: 'Course',
        subtitle: 'Academic',
        category: 'LEARNING',
        colorValue: const Color(0xFFFFC107).value, // Amber - Academic
        baseType: 'DEEP WORK',
      ),
      TaskNode(
        id: 'health',
        name: 'Health',
        subtitle: 'Gym',
        category: 'HEALTH',
        colorValue: const Color(0xFF4CAF50).value, // Green - Health
        baseType: 'PERSONAL',
      ),
      TaskNode(
        id: 'maintenance',
        name: 'Maintenance',
        subtitle: 'Eating',
        category: 'MAINTENANCE',
        colorValue: const Color(0xFF2196F3).value, // Blue - Maintenance
        baseType: 'PERSONAL',
      ),
      TaskNode(
        id: 'social_media',
        name: 'Social Media',
        subtitle: '',
        category: 'ENTERTAINMENT',
        colorValue: const Color(0xFFE91E63).value, // Pink - Social Media
        baseType: 'WASTED',
      ),
      TaskNode(
        id: 'youtube',
        name: 'YouTube',
        subtitle: '',
        category: 'ENTERTAINMENT',
        colorValue: const Color(0xFFFF0000).value, // Red - YouTube
        baseType: 'WASTED',
      ),
      TaskNode(
        id: 'sleep',
        name: 'Sleep',
        subtitle: 'Rest',
        category: 'REST',
        colorValue: const Color(0xFF3F51B5).value, // Indigo - Sleep
        baseType: 'SLEEP',
      ),
    ];

    for (var task in defaults) {
      await _taskBox!.put(task.id, task);
    }
  }

  // Category Management
  List<String> getCategories() {
    return _categoryBox?.keys.cast<String>().toList() ?? [];
  }

  String getCategoryBaseType(String category) {
    return _categoryBox?.get(category) ?? 'DEEP WORK';
  }

  Future<void> addCategory(String name, String baseType) async {
    await _categoryBox?.put(name, baseType);
    notifyListeners();
  }

  Future<void> deleteCategory(String name) async {
    await _categoryBox?.delete(name);
    notifyListeners();
  }

  Future<void> switchTask(String taskId) async {
    if (_currentEntry?.taskId == taskId) return;

    if (_currentEntry != null) {
      _currentEntry!.endTime = DateTime.now();
      await _currentEntry!.save();
    }

    final newEntry = TimeEntry(
      id: const Uuid().v4(),
      taskId: taskId,
      startTime: DateTime.now(),
    );

    await _timeBox!.add(newEntry);
    _history.insert(0, newEntry);
    _currentEntry = newEntry;

    notifyListeners();

    // Auto-tick attendance if applicable
    await autoTickAttendance(taskId);
  }

  Future<void> autoTickAttendance(String taskId) async {
    final now = DateTime.now();
    final events = getEventsForDate(now);

    // Find events that are currently active
    final activeEvents = events.where((e) {
      final isDuring = now.isAfter(e.startTime) && now.isBefore(e.endTime);
      return isDuring;
    });

    for (var event in activeEvents) {
      bool shouldTick = false;

      // Match by Link
      if (event.linkedTaskId == taskId) {
        shouldTick = true;
      }

      if (!shouldTick) {
        // Maybe the event title matches the task name?
        final task = getTaskById(taskId);
        if (task != null) {
          if (event.title.toLowerCase().contains(task.name.toLowerCase()) ||
              task.name.toLowerCase().contains(event.title.toLowerCase())) {
            shouldTick = true;
          }
        }
      }

      if (shouldTick && !event.isCompleted) {
        await toggleEventCompletion(event.id, now);
      }
    }
  }

  Future<void> _startUnknownTask() async {
    await switchTask(TaskNode.unknownId);
  }

  TaskNode? getTaskById(String id) {
    try {
      return _tasks.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  List<TimeEntry> getTodayEntries() {
    return getEntriesForDate(DateTime.now());
  }

  List<TimeEntry> getEntriesForDate(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return _history.where((e) {
      // Entry started on this day
      if (e.startTime.isAfter(dayStart) && e.startTime.isBefore(dayEnd)) {
        return true;
      }
      // Entry spans into this day (started before but ended during/after)
      if (e.startTime.isBefore(dayStart) &&
          (e.endTime == null || e.endTime!.isAfter(dayStart))) {
        return true;
      }
      return false;
    }).toList();
  }

  Future<void> addTask({
    required String name,
    String? subtitle,
    String category = '',
    String baseType = 'DEEP WORK',
    int? colorValue,
    String? linkedInputId,
  }) async {
    final task = TaskNode(
      id: const Uuid().v4(),
      name: name,
      subtitle: subtitle,
      category: category,
      colorValue: colorValue ?? Colors.grey.value,
      baseType: baseType,
      linkedInputId: linkedInputId,
    );

    await _taskBox!.put(task.id, task);
    _tasks = _taskBox!.values.toList();
    notifyListeners();
  }

  Future<void> updateTask(
    String id, {
    required String name,
    String? subtitle,
    String category = '',
    String baseType = 'DEEP WORK',
    int? colorValue,
    String? linkedInputId,
  }) async {
    final existingTask = getTaskById(id);
    if (existingTask == null) return;

    final updatedTask = TaskNode(
      id: id,
      name: name,
      subtitle: subtitle,
      category: category,
      colorValue: colorValue ?? existingTask.colorValue,
      baseType: baseType,
      linkedInputId: linkedInputId ?? existingTask.linkedInputId,
    );

    await _taskBox!.put(id, updatedTask);
    _tasks = _taskBox!.values.toList();
    notifyListeners();
  }

  Future<void> deleteTask(String id) async {
    if (id == TaskNode.unknownId) return;
    await _taskBox!.delete(id);
    _tasks = _taskBox!.values.toList();
    notifyListeners();
  }

  // ============ SCHEDULED EVENTS ============

  List<ScheduledEvent> getEventsForDate(
    DateTime date, {
    bool includeExcluded = false,
  }) {
    final dayStart = DateTime(date.year, date.month, date.day);
    // Use inclusive check for start of day

    List<ScheduledEvent> displayEvents = [];

    for (var e in _events) {
      bool isOccurring = false;
      DateTime? instanceStart;
      DateTime? instanceEnd;

      // Base start date (strip time)
      final eventStartDay = DateTime(
        e.startTime.year,
        e.startTime.month,
        e.startTime.day,
      );

      bool isCompleted = e.isCompleted;

      if (e.recurrenceType == 'none') {
        // One-time event
        if (eventStartDay.year == dayStart.year &&
            eventStartDay.month == dayStart.month &&
            eventStartDay.day == dayStart.day) {
          isOccurring = true;
          instanceStart = e.startTime;
          instanceEnd = e.endTime;
        }
      } else {
        // Recurring
        if (!dayStart.isBefore(eventStartDay)) {
          final dateKey = DateTime(dayStart.year, dayStart.month, dayStart.day);
          // date >= start
          bool endConditionMet = true;
          if (e.recurrenceEndTime != null) {
            final recurrenceEndDay = DateTime(
              e.recurrenceEndTime!.year,
              e.recurrenceEndTime!.month,
              e.recurrenceEndTime!.day,
            );
            if (dayStart.isAfter(recurrenceEndDay)) {
              endConditionMet = false;
            }
          }

          if (endConditionMet) {
            // CHECK EXCLUSIONS
            final dateKey = DateTime(
              dayStart.year,
              dayStart.month,
              dayStart.day,
            );
            final isExcluded =
                e.excludedDates?.any(
                  (d) =>
                      d.year == dateKey.year &&
                      d.month == dateKey.month &&
                      d.day == dateKey.day,
                ) ??
                false;

            if (!isExcluded || includeExcluded) {
              if (e.recurrenceType == 'daily') {
                isOccurring = true;
              } else if (e.recurrenceType == 'weekly') {
                if (e.recurrenceDays != null && e.recurrenceDays!.isNotEmpty) {
                  if (e.recurrenceDays!.contains(dayStart.weekday)) {
                    isOccurring = true;
                  }
                } else {
                  if (dayStart.weekday == eventStartDay.weekday) {
                    isOccurring = true;
                  }
                }
              }
            }
          }

          if (isOccurring) {
            // Create instance
            instanceStart = DateTime(
              dayStart.year,
              dayStart.month,
              dayStart.day,
              e.startTime.hour,
              e.startTime.minute,
            );
            final duration = e.duration;
            instanceEnd = instanceStart.add(duration);

            // Check completion for recurring events
            if (e.recurrenceType != 'none') {
              isCompleted =
                  e.completedDates?.any(
                    (d) =>
                        d.year == dateKey.year &&
                        d.month == dateKey.month &&
                        d.day == dateKey.day,
                  ) ??
                  false;
            }

            // Check if it was excluded (we need this to mark it as 'cancelled' if includeExcluded is true)
            final isExcludedDate =
                e.excludedDates?.any(
                  (d) =>
                      d.year == dateKey.year &&
                      d.month == dateKey.month &&
                      d.day == dateKey.day,
                ) ??
                false;
            if (isExcludedDate) {
              // We mark it using a temporary description or something?
              // Better is to pass it through ScheduledEvent.
              // Let's add a property to ScheduledEvent for transient 'isExcluded'?
              // ActuallyScheduledEvent already has excludedDates.
            }
          }
        }
      }

      if (isOccurring && instanceStart != null && instanceEnd != null) {
        displayEvents.add(
          ScheduledEvent(
            id: e.id,
            title: e.title,
            description: e.description,
            startTime: instanceStart,
            endTime: instanceEnd,
            colorValue: e.colorValue,
            isAllDay: e.isAllDay,
            linkedTaskId: e.linkedTaskId,
            recurrenceType: e.recurrenceType,
            recurrenceEndTime: e.recurrenceEndTime,
            recurrenceDays: e.recurrenceDays,
            isCompleted: isCompleted,
            excludedDates: e.excludedDates,
          ),
        );
      }
    }

    displayEvents.sort((a, b) => a.startTime.compareTo(b.startTime));
    return displayEvents;
  }

  Future<void> toggleEventCompletion(
    String eventId,
    DateTime instanceDate,
  ) async {
    final eventIndex = _events.indexWhere((e) => e.id == eventId);
    if (eventIndex == -1) return;
    final event = _events[eventIndex];

    if (event.recurrenceType == 'none') {
      // One-time event
      final newEvent = ScheduledEvent(
        id: event.id,
        title: event.title,
        description: event.description,
        startTime: event.startTime,
        endTime: event.endTime,
        colorValue: event.colorValue,
        isAllDay: event.isAllDay,
        linkedTaskId: event.linkedTaskId,
        recurrenceType: event.recurrenceType,
        recurrenceEndTime: event.recurrenceEndTime,
        recurrenceDays: event.recurrenceDays,
        isCompleted: !event.isCompleted,
        completedDates: event.completedDates,
      );
      await _eventBox!.put(event.id, newEvent);
    } else {
      // Recurring event
      final dateKey = DateTime(
        instanceDate.year,
        instanceDate.month,
        instanceDate.day,
      );
      List<DateTime> completedDates = List.from(event.completedDates ?? []);

      final existingIndex = completedDates.indexWhere(
        (d) =>
            d.year == dateKey.year &&
            d.month == dateKey.month &&
            d.day == dateKey.day,
      );

      if (existingIndex != -1) {
        completedDates.removeAt(existingIndex);
      } else {
        completedDates.add(dateKey);
      }

      final newEvent = ScheduledEvent(
        id: event.id,
        title: event.title,
        description: event.description,
        startTime: event.startTime,
        endTime: event.endTime,
        colorValue: event.colorValue,
        isAllDay: event.isAllDay,
        linkedTaskId: event.linkedTaskId,
        recurrenceType: event.recurrenceType,
        recurrenceEndTime: event.recurrenceEndTime,
        recurrenceDays: event.recurrenceDays,
        isCompleted: event.isCompleted, // Master flag unused for logic
        completedDates: completedDates,
      );
      await _eventBox!.put(event.id, newEvent);
    }
    _events = _eventBox!.values.toList();
    _events.sort((a, b) => a.startTime.compareTo(b.startTime));
    notifyListeners();
  }

  Future<void> addEvent({
    required String title,
    String? description,
    required DateTime startTime,
    required DateTime endTime,
    required int colorValue,
    bool isAllDay = false,
    String? linkedTaskId,
    String recurrenceType = 'none',
    DateTime? recurrenceEndTime,
    List<int>? recurrenceDays,
  }) async {
    final event = ScheduledEvent(
      id: const Uuid().v4(),
      title: title,
      description: description,
      startTime: startTime,
      endTime: endTime,
      colorValue: colorValue,
      isAllDay: isAllDay,
      linkedTaskId: linkedTaskId,
      recurrenceType: recurrenceType,
      recurrenceEndTime: recurrenceEndTime,
      recurrenceDays: recurrenceDays,
    );
    await _eventBox!.put(event.id, event);
    _events = _eventBox!.values.toList();
    _events.sort((a, b) => a.startTime.compareTo(b.startTime));

    notifyListeners();
  }

  Future<void> updateEvent(
    String id, {
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    int? colorValue,
    bool? isAllDay,
    String? linkedTaskId,
    String? recurrenceType,
    DateTime? recurrenceEndTime,
    List<int>? recurrenceDays,
  }) async {
    final event = _events.firstWhere((e) => e.id == id);
    final newEvent = ScheduledEvent(
      id: id,
      title: title ?? event.title,
      description: description ?? event.description,
      startTime: startTime ?? event.startTime,
      endTime: endTime ?? event.endTime,
      colorValue: colorValue ?? event.colorValue,
      isAllDay: isAllDay ?? event.isAllDay,
      linkedTaskId: linkedTaskId ?? event.linkedTaskId,
      recurrenceType: recurrenceType ?? event.recurrenceType,
      recurrenceEndTime: recurrenceEndTime ?? event.recurrenceEndTime,
      recurrenceDays: recurrenceDays ?? event.recurrenceDays,
      isCompleted: event.isCompleted,
      completedDates: event.completedDates,
      excludedDates: event.excludedDates,
    );
    await _eventBox!.put(id, newEvent);
    _events = _eventBox!.values.toList();
    _events.sort((a, b) => a.startTime.compareTo(b.startTime));
    notifyListeners();
  }

  Future<void> deleteEvent(String id) async {
    await _eventBox!.delete(id);
    _events = _eventBox!.values.toList();
    _events.sort((a, b) => a.startTime.compareTo(b.startTime));
    notifyListeners();
  }

  Future<void> toggleEventExclusion(String eventId, DateTime date) async {
    final eventIndex = _events.indexWhere((e) => e.id == eventId);
    if (eventIndex == -1) return;
    final event = _events[eventIndex];

    final dateKey = DateTime(date.year, date.month, date.day);
    List<DateTime> excluded = List.from(event.excludedDates ?? []);

    final existingIndex = excluded.indexWhere(
      (d) =>
          d.year == dateKey.year &&
          d.month == dateKey.month &&
          d.day == dateKey.day,
    );

    if (existingIndex != -1) {
      excluded.removeAt(existingIndex);
    } else {
      excluded.add(dateKey);
    }

    final newEvent = ScheduledEvent(
      id: event.id,
      title: event.title,
      description: event.description,
      startTime: event.startTime,
      endTime: event.endTime,
      colorValue: event.colorValue,
      isAllDay: event.isAllDay,
      linkedTaskId: event.linkedTaskId,
      recurrenceType: event.recurrenceType,
      recurrenceEndTime: event.recurrenceEndTime,
      recurrenceDays: event.recurrenceDays,
      isCompleted: event.isCompleted,
      completedDates: event.completedDates,
      excludedDates: excluded,
    );

    await _eventBox!.put(event.id, newEvent);
    _events = _eventBox!.values.toList();
    _events.sort((a, b) => a.startTime.compareTo(b.startTime));
    notifyListeners();
  }

  // ============ GOALS ============

  Future<void> addGoal({
    required String name,
    String? taskId,
    required int targetMinutes,
    required int colorValue,
    String contributionType = 'time',
    int? targetCount,
    String? eventTitlePattern,
  }) async {
    final goal = Goal(
      id: const Uuid().v4(),
      name: name,
      taskId: taskId,
      targetMinutes: targetMinutes,
      colorValue: colorValue,
      createdAt: DateTime.now(),
      contributionType: contributionType,
      targetCount: targetCount,
      eventTitlePattern: eventTitlePattern,
    );
    await _goalBox!.put(goal.id, goal);
    _goals = _goalBox!.values.toList();
    notifyListeners();
  }

  Future<void> updateGoal(
    String id, {
    required String name,
    String? taskId,
    required int targetMinutes,
    required int colorValue,
    String? contributionType,
    int? targetCount,
    String? eventTitlePattern,
  }) async {
    final existing = _goals.firstWhere((g) => g.id == id);
    final goal = Goal(
      id: id,
      name: name,
      taskId: taskId,
      targetMinutes: targetMinutes,
      colorValue: colorValue,
      createdAt: existing.createdAt,
      contributionType: contributionType ?? existing.contributionType,
      targetCount: targetCount ?? existing.targetCount,
      eventTitlePattern: eventTitlePattern ?? existing.eventTitlePattern,
    );
    await _goalBox!.put(id, goal);
    _goals = _goalBox!.values.toList();
    notifyListeners();
  }

  Future<void> deleteGoal(String id) async {
    await _goalBox!.delete(id);
    _goals = _goalBox!.values.toList();
    notifyListeners();
  }

  double getGoalProgress(Goal goal) {
    if (goal.contributionType == 'event') {
      final now = DateTime.now();
      final events = getEventsForDate(now);

      // Filter events based on either taskId or eventTitlePattern
      final matchingEvents = events.where((e) {
        // If we have an eventTitlePattern, match by title
        if (goal.eventTitlePattern != null &&
            goal.eventTitlePattern!.isNotEmpty) {
          return e.title.toLowerCase().contains(
            goal.eventTitlePattern!.toLowerCase(),
          );
        }
        // Otherwise, match by linked task
        if (goal.taskId != null && goal.taskId!.isNotEmpty) {
          return e.linkedTaskId == goal.taskId;
        }
        // If neither is set, count all completed events
        return true;
      }).toList();

      final completedCount = matchingEvents.where((e) => e.isCompleted).length;
      final target = goal.targetCount ?? 1;
      if (target == 0) return 0.0;
      return completedCount / target;
    }

    // Re-calculating cleanly to ensure we only count time that falls on TODAY
    final now = DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    // Get strictly entries that overlap with today
    // (Note: _getEntriesForDate already filters roughly, but we need precise overlap duration)
    final todayEntries = getEntriesForDate(now);

    // Use seconds to avoid integer truncation issues with small durations
    int totalSeconds = 0;

    for (var entry in todayEntries) {
      if (goal.taskId == null || entry.taskId == goal.taskId) {
        // Calculate strict overlap
        final eStart = entry.startTime;
        final eEnd = entry.endTime ?? now;

        // Determine the start/end points within the day window
        // (Since getEntriesForDate handles the check, we just clamp here)
        final effectiveStart = eStart.isBefore(dayStart) ? dayStart : eStart;
        final effectiveEnd = eEnd.isAfter(dayEnd) ? dayEnd : eEnd;

        if (effectiveEnd.isAfter(effectiveStart)) {
          totalSeconds += effectiveEnd.difference(effectiveStart).inSeconds;
        }
      }
    }

    final totalMinutes =
        totalSeconds / 60.0; // Floating point minutes for better precision
    if (goal.targetMinutes == 0) return 0.0;

    return totalMinutes / goal.targetMinutes;
  }

  int getGoalStreak(Goal goal) {
    int streak = 0;
    // Start checking from yesterday
    DateTime date = DateTime.now().subtract(const Duration(days: 1));

    while (streak < 365) {
      bool metaprogress = false;

      if (goal.contributionType == 'event') {
        // Event logic
        final events = getEventsForDate(date);

        // Filter events based on either taskId or eventTitlePattern
        final matchingEvents = events.where((e) {
          if (goal.eventTitlePattern != null &&
              goal.eventTitlePattern!.isNotEmpty) {
            return e.title.toLowerCase().contains(
              goal.eventTitlePattern!.toLowerCase(),
            );
          }
          if (goal.taskId != null && goal.taskId!.isNotEmpty) {
            return e.linkedTaskId == goal.taskId;
          }
          return true;
        }).toList();

        final completedCount = matchingEvents
            .where((e) => e.isCompleted)
            .length;
        if (completedCount >= (goal.targetCount ?? 1)) {
          metaprogress = true;
        }
      } else {
        // Time logic
        final dayStart = DateTime(date.year, date.month, date.day);
        final dayEnd = dayStart.add(const Duration(days: 1));
        final entries = getEntriesForDate(date);
        int totalSeconds = 0;

        for (var entry in entries) {
          if (goal.taskId == null || entry.taskId == goal.taskId) {
            final eStart = entry.startTime;
            final eEnd =
                entry.endTime ?? DateTime.now(); // Should have endTime usually

            final effectiveStart = eStart.isBefore(dayStart)
                ? dayStart
                : eStart;
            final effectiveEnd = eEnd.isAfter(dayEnd) ? dayEnd : eEnd;

            if (effectiveEnd.isAfter(effectiveStart)) {
              totalSeconds += effectiveEnd.difference(effectiveStart).inSeconds;
            }
          }
        }
        final totalMinutes = totalSeconds / 60.0;
        if (totalMinutes >= goal.targetMinutes) {
          metaprogress = true;
        }
      }

      if (metaprogress) {
        streak++;
        date = date.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    // Check today separately to add to streak if currently met
    if (getGoalProgress(goal) >= 1.0) {
      streak++;
    }

    return streak;
  }

  /// Get attendance statistics for event-based goals (class attendance tracking)
  /// Returns counts for: today, this week, this month, this semester
  Map<String, int> getAttendanceStats(Goal goal) {
    if (goal.contributionType != 'event') {
      return {'today': 0, 'week': 0, 'month': 0, 'semester': 0, 'total': 0};
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Week start (Monday)
    final weekStart = today.subtract(Duration(days: today.weekday - 1));

    // Month start
    final monthStart = DateTime(now.year, now.month, 1);

    // Semester start (assume academic semesters: Jan-May, Jun-Aug, Sep-Dec)
    DateTime semesterStart;
    if (now.month >= 1 && now.month <= 5) {
      semesterStart = DateTime(now.year, 1, 1);
    } else if (now.month >= 6 && now.month <= 8) {
      semesterStart = DateTime(now.year, 6, 1);
    } else {
      semesterStart = DateTime(now.year, 9, 1);
    }

    int todayAttended = 0;
    int todayTotal = 0;

    int weekAttended = 0;
    int weekTotal = 0;

    int monthAttended = 0;
    int monthTotal = 0;

    int semesterAttended = 0;
    int semesterTotal = 0;

    // Iterate through all dates from semester start to today
    DateTime checkDate = semesterStart;
    while (!checkDate.isAfter(today)) {
      // Use includeExcluded to get all events, then filter out cancelled ones
      final events = getEventsForDate(checkDate, includeExcluded: true);

      // Check if checkDate is today
      final isToday =
          checkDate.year == today.year &&
          checkDate.month == today.month &&
          checkDate.day == today.day;

      // Filter events based on goal criteria
      final potentialEvents = events.where((e) {
        bool matches = false;
        if (goal.eventTitlePattern != null &&
            goal.eventTitlePattern!.isNotEmpty) {
          // Normalize whitespace: trim and replace multiple spaces with single space
          final normalizedTitle = e.title.trim().toLowerCase().replaceAll(
            RegExp(r'\s+'),
            ' ',
          );
          final normalizedPattern = goal.eventTitlePattern!
              .trim()
              .toLowerCase()
              .replaceAll(RegExp(r'\s+'), ' ');
          matches = normalizedTitle == normalizedPattern;

          if (matches) {
            // print('DEBUG: Matched ${e.title}');
          } else if (e.title.toLowerCase().contains(
            goal.eventTitlePattern!.toLowerCase(),
          )) {
            print(
              'DEBUG: Mismatch on Strict but Contains passed: "${e.title}" vs "${goal.eventTitlePattern!}"',
            );
          }
        } else if (goal.taskId != null && goal.taskId!.isNotEmpty) {
          matches = e.linkedTaskId == goal.taskId;
        } else {
          matches = true;
        }

        if (!matches) return false;

        // Check if this date is excluded (cancelled class)
        final dateKey = DateTime(
          checkDate.year,
          checkDate.month,
          checkDate.day,
        );
        final isCancelled =
            e.excludedDates?.any(
              (d) =>
                  d.year == dateKey.year &&
                  d.month == dateKey.month &&
                  d.day == dateKey.day,
            ) ??
            false;

        if (isCancelled) return false;

        // For today, only count in Total (scheduled) if it's already completed
        // OR the start time has passed. This avoids "0/1" for future classes.
        if (isToday) {
          return e.isCompleted || e.startTime.isBefore(now);
        }
        return true;
      }).toList();

      final attendedEvents = potentialEvents
          .where((e) => e.isCompleted)
          .toList();

      final pCount = potentialEvents.length;
      final aCount = attendedEvents.length;

      // Check if this date falls within time periods
      if (isToday) {
        todayAttended += aCount;
        todayTotal += pCount;
      }
      if (!checkDate.isBefore(weekStart)) {
        weekAttended += aCount;
        weekTotal += pCount;
      }
      if (!checkDate.isBefore(monthStart)) {
        monthAttended += aCount;
        monthTotal += pCount;
      }
      semesterAttended += aCount;
      semesterTotal += pCount;

      checkDate = checkDate.add(const Duration(days: 1));
    }

    return {
      'today': todayAttended,
      'todayTotal': todayTotal,
      'week': weekAttended,
      'weekTotal': weekTotal,
      'month': monthAttended,
      'monthTotal': monthTotal,
      'semester': semesterAttended,
      'semesterTotal': semesterTotal,
      'total': semesterTotal,
      'missed': semesterTotal - semesterAttended,
    };
  }

  // ==========================================
  // LEARNING HUB LOGIC
  // ==========================================
  Set<String> get availableInputTypes {
    final defaults = {'book', 'podcast', 'video', 'course', 'article'};
    final existing = _learningInputs.map((i) => i.type).toSet();
    return defaults.union(existing).union(_customLearningCategories.toSet());
  }

  Future<void> addLearningCategory(String category) async {
    if (!availableInputTypes.contains(category)) {
      await _learningCategoryBox!.add(category);
      _customLearningCategories = _learningCategoryBox!.values.toList();
      notifyListeners();
    }
  }

  Future<void> deleteLearningCategory(
    String category, {
    bool deleteItems = false,
  }) async {
    // Remove from persistent list
    final keyToDelete = _learningCategoryBox!.keys.firstWhere(
      (k) => _learningCategoryBox!.get(k) == category,
      orElse: () => null,
    );
    if (keyToDelete != null) {
      await _learningCategoryBox!.delete(keyToDelete);
      _customLearningCategories = _learningCategoryBox!.values.toList();
    }

    if (deleteItems) {
      // Delete all items of this type
      final idsToDelete = _learningInputs
          .where((i) => i.type == category)
          .map((i) => i.id)
          .toList();
      for (final id in idsToDelete) {
        await _learningInputBox!.delete(id);
      }
      _learningInputs = _learningInputBox!.values.toList();
      _learningInputs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      // Move items to 'other' (or keep them? User request implied full delete or edit)
      // If we strictly follow "Delete Category" but NOT items, we should rename items to something generic
      // Or we do nothing to items, and they just show up as their own category still because of 'existing' check.
      // Let's implement 'rename items to other' as a safer default if not deleting.
      final itemsToUpdate = _learningInputs
          .where((i) => i.type == category)
          .toList();
      for (var item in itemsToUpdate) {
        item.type = 'other';
        await _learningInputBox!.put(item.id, item);
      }
      _learningInputs = _learningInputBox!.values.toList();
      _learningInputs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    notifyListeners();
  }

  Future<void> renameLearningCategory(String oldName, String newName) async {
    // 1. Update persistent list
    final keyToUpdate = _learningCategoryBox!.keys.firstWhere(
      (k) => _learningCategoryBox!.get(k) == oldName,
      orElse: () => null,
    );
    if (keyToUpdate != null) {
      await _learningCategoryBox!.put(keyToUpdate, newName);
      _customLearningCategories = _learningCategoryBox!.values.toList();
    } else {
      // If it wasn't in persistent list (e.g. was just from items), add it now
      await addLearningCategory(newName);
    }

    // 2. Update all items
    final itemsToUpdate = _learningInputs
        .where((i) => i.type == oldName)
        .toList();
    for (var item in itemsToUpdate) {
      item.type = newName;
      await _learningInputBox!.put(item.id, item);
    }
    _learningInputs = _learningInputBox!.values.toList();
    _learningInputs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  Future<void> addLearningInput(LearningInput input) async {
    await _learningInputBox!.put(input.id, input);
    _learningInputs = _learningInputBox!.values.toList();
    _learningInputs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  Future<void> updateLearningInput(LearningInput input) async {
    await _learningInputBox!.put(input.id, input);
    _learningInputs = _learningInputBox!.values.toList();
    _learningInputs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  Future<void> deleteLearningInput(String id) async {
    await _learningInputBox!.delete(id);
    _learningInputs = _learningInputBox!.values.toList();
    _learningInputs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  Future<void> updateLearningInputDisplayMode(
    String id,
    String displayMode,
  ) async {
    final input = _learningInputs.firstWhere((i) => i.id == id);
    input.displayMode = displayMode;
    await _learningInputBox!.put(id, input);
    notifyListeners();
  }

  // DEADLINES
  Future<void> addDeadline(DeadlineItem item) async {
    await _deadlineBox!.put(item.id, item);
    _deadlines = _deadlineBox!.values.toList();
    _deadlines.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    notifyListeners();
  }

  Future<void> updateDeadline(DeadlineItem item) async {
    await _deadlineBox!.put(item.id, item);
    _deadlines = _deadlineBox!.values.toList();
    _deadlines.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    notifyListeners();
  }

  Future<void> deleteDeadline(String id) async {
    await _deadlineBox!.delete(id);
    _deadlines = _deadlineBox!.values.toList();
    _deadlines.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    notifyListeners();
  }

  Future<void> linkTaskToInput(String taskId, String inputId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      final updatedTask = TaskNode(
        id: task.id,
        name: task.name,
        subtitle: task.subtitle,
        category: task.category,
        colorValue: task.colorValue,
        baseType: task.baseType,
        linkedInputId: inputId,
      );

      _tasks[index] = updatedTask;
      if (_taskBox != null) {
        await _taskBox!.put(task.id, updatedTask);
      }
      notifyListeners();
    }
  }

  int getDurationForInput(String inputId, {DateTime? start, DateTime? end}) {
    final linkedTaskIds = _tasks
        .where((t) => t.linkedInputId == inputId)
        .map((t) => t.id)
        .toSet();

    return _history
        .where((e) {
          if (!linkedTaskIds.contains(e.taskId)) return false;
          if (start != null && e.startTime.isBefore(start)) return false;
          if (end != null && e.startTime.isAfter(end)) return false;
          return true;
        })
        .fold(0, (sum, e) => sum + e.duration.inSeconds);
  }

  TaskNode? getTaskForInput(String inputId) {
    try {
      return _tasks.firstWhere((t) => t.linkedInputId == inputId);
    } catch (e) {
      return null;
    }
  }

  DateTime? getLastActiveTimeForInput(String inputId) {
    final linkedTaskIds = _tasks
        .where((t) => t.linkedInputId == inputId)
        .map((t) => t.id)
        .toSet();

    try {
      final entry = _history.firstWhere(
        (e) => linkedTaskIds.contains(e.taskId),
      );
      return entry.endTime ?? DateTime.now();
    } catch (e) {
      return null;
    }
  }
}
