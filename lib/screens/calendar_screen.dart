import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/time_tracking_provider.dart';
import '../models/scheduled_event.dart';
import '../models/task_node.dart';
import '../constants/colors.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _selectedDate;
  late DateTime _focusedMonth;
  bool _isMonthExpanded = false;
  late ScrollController _timelineController;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _focusedMonth = DateTime.now();
    _timelineController = ScrollController();

    // Scroll to current hour on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentTime();
    });
  }

  void _scrollToCurrentTime() {
    if (!_timelineController.hasClients) return;
    final currentHour = DateTime.now().hour;
    final offset = (currentHour * 70.0) - 100;
    if (offset > 0) {
      _timelineController.animateTo(
        offset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    }
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    // Scroll to current time if selecting today
    if (_isSameDay(date, DateTime.now())) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrentTime();
      });
    }
  }

  @override
  void dispose() {
    _timelineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TimeTrackerProvider>(
      builder: (context, provider, child) {
        final todayEvents = provider.getEventsForDate(_selectedDate);
        final now = DateTime.now();
        final isToday = _isSameDay(_selectedDate, now);

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(isToday),
                _buildMonthSelector(),
                if (_isMonthExpanded) _buildMonthGrid(provider),
                _buildNextHoursSnapshot(provider, todayEvents, now, isToday),
                Expanded(
                  child: _buildFullDayTimeline(
                    provider,
                    todayEvents,
                    now,
                    isToday,
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 80),
            child: FloatingActionButton(
              heroTag: 'event',
              onPressed: () => _showAddEventDialog(context, provider, null),
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.black,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.add, size: 24),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isToday) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isToday
                    ? 'TODAY'
                    : DateFormat('EEEE').format(_selectedDate).toUpperCase(),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('MMMM d, yyyy').format(_selectedDate),
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            ],
          ),
          if (!isToday)
            GestureDetector(
              onTap: () {
                _focusedMonth = DateTime.now();
                _selectDate(DateTime.now());
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Go to Today',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return GestureDetector(
      onTap: () => setState(() => _isMonthExpanded = !_isMonthExpanded),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_month,
                  color: Colors.grey.shade500,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  DateFormat('MMMM yyyy').format(_focusedMonth),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Icon(
              _isMonthExpanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.grey.shade500,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthGrid(TimeTrackerProvider provider) {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDay = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final startWeekday = firstDay.weekday % 7;

    final days = <Widget>[];
    for (final d in ['S', 'M', 'T', 'W', 'T', 'F', 'S']) {
      days.add(
        Center(
          child: Text(
            d,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
    for (int i = 0; i < startWeekday; i++) {
      days.add(const SizedBox());
    }
    for (int day = 1; day <= lastDay.day; day++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
      final isSelected = _isSameDay(date, _selectedDate);
      final isToday = _isSameDay(date, DateTime.now());
      final hasEvents = provider.getEventsForDate(date).isNotEmpty;

      days.add(
        GestureDetector(
          onTap: () {
            _isMonthExpanded = false;
            _selectDate(date);
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.accent.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: isToday && !isSelected
                  ? Border.all(color: AppColors.accent, width: 1)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.accent
                        : AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                if (hasEvents)
                  Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  Icons.chevron_left,
                  color: Colors.grey.shade500,
                  size: 20,
                ),
                onPressed: () => setState(
                  () => _focusedMonth = DateTime(
                    _focusedMonth.year,
                    _focusedMonth.month - 1,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade500,
                  size: 20,
                ),
                onPressed: () => setState(
                  () => _focusedMonth = DateTime(
                    _focusedMonth.year,
                    _focusedMonth.month + 1,
                  ),
                ),
              ),
            ],
          ),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 7,
            childAspectRatio: 1.2,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            children: days,
          ),
        ],
      ),
    );
  }

  Widget _buildNextHoursSnapshot(
    TimeTrackerProvider provider,
    List<ScheduledEvent> events,
    DateTime now,
    bool isToday,
  ) {
    if (!isToday) return const SizedBox.shrink();

    final upcoming = events
        .where(
          (e) =>
              e.startTime.isAfter(now) &&
              e.startTime.isBefore(now.add(const Duration(hours: 2))),
        )
        .toList();
    final current = events
        .where((e) => e.startTime.isBefore(now) && e.endTime.isAfter(now))
        .toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade900, Colors.grey.shade900.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: current.isNotEmpty ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                current.isNotEmpty
                    ? 'NOW: ${current.first.title}'
                    : 'FREE TIME',
                style: TextStyle(
                  color: current.isNotEmpty
                      ? AppColors.textPrimary
                      : Colors.grey.shade500,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (upcoming.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'NEXT: ${upcoming.first.title} at ${DateFormat('h:mm a').format(upcoming.first.startTime)}',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
            ),
          ] else if (current.isEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Nothing scheduled for the next 2 hours',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  // ============ FULL DAY TIMELINE ============
  static const double _hourHeight = 60.0; // Height per hour slot

  Widget _buildFullDayTimeline(
    TimeTrackerProvider provider,
    List<ScheduledEvent> events,
    DateTime now,
    bool isToday,
  ) {
    // Calculate event positions for overlapping detection
    final eventPositions = _calculateEventPositions(events);

    return SingleChildScrollView(
      controller: _timelineController,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      child: SizedBox(
        height: 24 * _hourHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time labels column
            SizedBox(
              width: 50,
              child: Column(
                children: List.generate(24, (hour) {
                  final timeLabel = DateFormat(
                    'h a',
                  ).format(DateTime(2000, 1, 1, hour));
                  final hourStart = DateTime(
                    _selectedDate.year,
                    _selectedDate.month,
                    _selectedDate.day,
                    hour,
                  );
                  final hourEnd = hourStart.add(const Duration(hours: 1));
                  final isPast = isToday && hourEnd.isBefore(now);
                  final isCurrent =
                      isToday &&
                      hourStart.isBefore(now) &&
                      hourEnd.isAfter(now);

                  return SizedBox(
                    height: _hourHeight,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          timeLabel,
                          style: TextStyle(
                            color: isCurrent
                                ? AppColors.accent
                                : (isPast
                                      ? Colors.grey.shade700
                                      : Colors.grey.shade500),
                            fontSize: 11,
                            fontWeight: isCurrent
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Timeline indicator column
            SizedBox(
              width: 10,
              child: Column(
                children: List.generate(24, (hour) {
                  final hourStart = DateTime(
                    _selectedDate.year,
                    _selectedDate.month,
                    _selectedDate.day,
                    hour,
                  );
                  final hourEnd = hourStart.add(const Duration(hours: 1));
                  final isPast = isToday && hourEnd.isBefore(now);
                  final isCurrent =
                      isToday &&
                      hourStart.isBefore(now) &&
                      hourEnd.isAfter(now);

                  return SizedBox(
                    height: _hourHeight,
                    child: Column(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCurrent
                                ? AppColors.accent
                                : (isPast
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade700),
                            border: isCurrent
                                ? Border.all(color: AppColors.accent, width: 2)
                                : null,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            width: 1,
                            color: isPast
                                ? Colors.grey.shade800
                                : Colors.grey.shade700.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(width: 12),

            // Events stack
            Expanded(
              child: Stack(
                children: [
                  // Background hour slots (tappable)
                  ...List.generate(24, (hour) {
                    final hourStart = DateTime(
                      _selectedDate.year,
                      _selectedDate.month,
                      _selectedDate.day,
                      hour,
                    );
                    final hourEnd = hourStart.add(const Duration(hours: 1));
                    final isPast = isToday && hourEnd.isBefore(now);
                    final isCurrent =
                        isToday &&
                        hourStart.isBefore(now) &&
                        hourEnd.isAfter(now);

                    return Positioned(
                      top: hour * _hourHeight,
                      left: 0,
                      right: 0,
                      height: _hourHeight,
                      child: GestureDetector(
                        onTap: () =>
                            _showAddEventDialog(context, provider, null, hour),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 2),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? Colors.grey.shade900.withOpacity(0.3)
                                : (isPast
                                      ? Colors.grey.shade900.withOpacity(0.05)
                                      : Colors.transparent),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isCurrent
                                  ? AppColors.accent.withOpacity(0.2)
                                  : (isPast
                                        ? Colors.grey.shade800.withOpacity(0.05)
                                        : Colors.grey.shade800.withOpacity(
                                            0.1,
                                          )),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),

                  // Event cards
                  ...eventPositions.map((pos) {
                    final event = pos['event'] as ScheduledEvent;
                    final column = pos['column'] as int;
                    final totalColumns = pos['totalColumns'] as int;

                    final startMinutes =
                        event.startTime.hour * 60 + event.startTime.minute;
                    final endMinutes =
                        event.endTime.hour * 60 + event.endTime.minute;
                    final durationMinutes = endMinutes - startMinutes;

                    final top = (startMinutes / 60.0) * _hourHeight;
                    final height = (durationMinutes / 60.0) * _hourHeight;

                    // Calculate width and left position for overlapping events
                    final eventWidth = 1.0 / totalColumns;
                    final leftPercent = column * eventWidth;

                    final hourEnd = DateTime(
                      _selectedDate.year,
                      _selectedDate.month,
                      _selectedDate.day,
                      event.startTime.hour + 1,
                    );
                    final isPast = isToday && hourEnd.isBefore(now);
                    final isCurrent =
                        isToday &&
                        event.startTime.isBefore(now) &&
                        event.endTime.isAfter(now);

                    return Positioned(
                      top: top,
                      left:
                          leftPercent *
                          (MediaQuery.of(context).size.width -
                              120), // Adjust for padding
                      width:
                          (MediaQuery.of(context).size.width - 120) *
                              eventWidth -
                          4,
                      height: height.clamp(30.0, double.infinity),
                      child: _buildTimelineEventCard(
                        event,
                        isPast,
                        isCurrent,
                        provider,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Calculate positions for overlapping events
  List<Map<String, dynamic>> _calculateEventPositions(
    List<ScheduledEvent> events,
  ) {
    if (events.isEmpty) return [];

    // Sort events by start time
    final sortedEvents = List<ScheduledEvent>.from(events)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    List<Map<String, dynamic>> positions = [];
    List<List<ScheduledEvent>> columns = [];

    for (var event in sortedEvents) {
      // Find a column where this event doesn't overlap
      int columnIndex = -1;
      for (int i = 0; i < columns.length; i++) {
        bool canFit = true;
        for (var existingEvent in columns[i]) {
          if (_eventsOverlap(event, existingEvent)) {
            canFit = false;
            break;
          }
        }
        if (canFit) {
          columnIndex = i;
          break;
        }
      }

      if (columnIndex == -1) {
        // Create a new column
        columns.add([event]);
        columnIndex = columns.length - 1;
      } else {
        columns[columnIndex].add(event);
      }

      positions.add({
        'event': event,
        'column': columnIndex,
        'totalColumns': 1, // Will be updated later
      });
    }

    // Update total columns for each event based on overlapping groups
    for (var pos in positions) {
      final event = pos['event'] as ScheduledEvent;
      int maxOverlap = 1;

      for (var otherPos in positions) {
        if (pos != otherPos) {
          final otherEvent = otherPos['event'] as ScheduledEvent;
          if (_eventsOverlap(event, otherEvent)) {
            maxOverlap = columns.length > maxOverlap
                ? columns.length
                : maxOverlap;
          }
        }
      }

      // Find all events that overlap with this one to determine proper column count
      List<ScheduledEvent> overlappingEvents = [event];
      for (var otherPos in positions) {
        final otherEvent = otherPos['event'] as ScheduledEvent;
        if (event != otherEvent && _eventsOverlap(event, otherEvent)) {
          overlappingEvents.add(otherEvent);
        }
      }
      pos['totalColumns'] = overlappingEvents.length > 1
          ? overlappingEvents.length
          : 1;
    }

    return positions;
  }

  bool _eventsOverlap(ScheduledEvent a, ScheduledEvent b) {
    return a.startTime.isBefore(b.endTime) && a.endTime.isAfter(b.startTime);
  }

  Widget _buildTimelineEventCard(
    ScheduledEvent event,
    bool isPast,
    bool isCurrent,
    TimeTrackerProvider provider,
  ) {
    final eventColor = Color(event.colorValue);

    // Check if THIS specific event is happening right now
    final now = DateTime.now();
    final isEventActive =
        now.isAfter(event.startTime) && now.isBefore(event.endTime);

    final isCompleted = event.isCompleted;

    // Calculate duration for compact mode
    final durationMinutes = event.endTime.difference(event.startTime).inMinutes;

    // Compact mode for short events (less than 45 min)
    final isCompact = durationMinutes < 45;

    return GestureDetector(
      onTap: () => _showAddEventDialog(context, provider, event),
      child: Container(
        margin: const EdgeInsets.all(1),
        padding: EdgeInsets.symmetric(
          horizontal: 6,
          vertical: isCompact ? 2 : 6,
        ),
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              eventColor.withOpacity(isPast ? 0.15 : 0.3),
              eventColor.withOpacity(isPast ? 0.08 : 0.15),
            ],
          ),
          borderRadius: BorderRadius.circular(6),
          border: isEventActive
              ? Border.all(color: eventColor, width: 2)
              : Border.all(color: eventColor.withOpacity(0.4), width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: isPast ? Colors.grey : eventColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    event.title,
                    style: TextStyle(
                      color: isPast && !isCompleted
                          ? Colors.grey
                          : AppColors.textPrimary,
                      fontSize: isCompact ? 10 : 11,
                      fontWeight: FontWeight.w600,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      overflow: TextOverflow.ellipsis,
                    ),
                    maxLines: 1,
                  ),
                  if (!isCompact) ...[
                    Text(
                      '${DateFormat('h:mm').format(event.startTime)} - ${DateFormat('h:mm a').format(event.endTime)}',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 9,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Only show checkbox for non-compact events
            if (!isCompact)
              GestureDetector(
                onTap: () {
                  provider.toggleEventCompletion(event.id, event.startTime);
                },
                child: Icon(
                  isCompleted ? Icons.check_circle : Icons.circle_outlined,
                  color: isCompleted ? AppColors.success : Colors.grey.shade600,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============ DIALOGS ============
  void _showAddEventDialog(
    BuildContext context,
    TimeTrackerProvider provider, [
    ScheduledEvent? event,
    int? defaultHour,
  ]) {
    final titleController = TextEditingController(text: event?.title ?? '');
    final descController = TextEditingController(
      text: event?.description ?? '',
    );

    // Use defaultHour if provided (when tapping on empty time slot), otherwise use event time or current time
    final initialHour =
        defaultHour ??
        (event != null ? event.startTime.hour : TimeOfDay.now().hour);
    TimeOfDay startTime = event != null
        ? TimeOfDay.fromDateTime(event.startTime)
        : TimeOfDay(hour: initialHour, minute: 0);
    TimeOfDay endTime = event != null
        ? TimeOfDay.fromDateTime(event.endTime)
        : TimeOfDay(hour: (initialHour + 1) % 24, minute: 0);
    Color selectedColor = event != null
        ? Color(event.colorValue)
        : AppColors.palette[0];
    String? linkedTaskId = event?.linkedTaskId;

    // Recurrence State
    String recurrenceType = event?.recurrenceType ?? 'none';
    DateTime? recurrenceEndTime = event?.recurrenceEndTime;
    Set<int> recurrenceDays = event?.recurrenceDays?.toSet() ?? {};

    // If weekly and no days set, default to current start day
    if (recurrenceType == 'weekly' && recurrenceDays.isEmpty) {
      // If event exists, use its start day. If new, use selectedDate
      recurrenceDays.add(
        event != null ? event.startTime.weekday : _selectedDate.weekday,
      );
    }

    final isEditing = event != null;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Edit Event' : 'New Event',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isEditing)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          // Confirm delete
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: Colors.grey.shade900,
                              title: const Text(
                                'Delete Event',
                                style: TextStyle(color: Colors.white),
                              ),
                              content: Text(
                                event.recurrenceType != 'none'
                                    ? 'This is a recurring event.'
                                    : 'Are you sure you want to delete this event?',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                                if (event.recurrenceType != 'none')
                                  TextButton(
                                    onPressed: () async {
                                      await provider.toggleEventExclusion(
                                        event.id,
                                        event.startTime,
                                      );
                                      if (context.mounted) {
                                        Navigator.pop(ctx);
                                        Navigator.pop(context);
                                      }
                                    },
                                    child: const Text(
                                      'Delete This Instance',
                                      style: TextStyle(color: Colors.orange),
                                    ),
                                  ),
                                TextButton(
                                  onPressed: () {
                                    provider.deleteEvent(event.id);
                                    Navigator.pop(ctx); // Close Alert
                                    Navigator.pop(context); // Close Sheet
                                  },
                                  child: Text(
                                    event.recurrenceType != 'none'
                                        ? 'Delete All'
                                        : 'Delete',
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: _inputDecoration('Event title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: _inputDecoration('Description (optional)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTimePicker('Start', startTime, (t) {
                        setDialogState(() {
                          // Calculate current duration
                          final oldDuration =
                              (endTime.hour * 60 + endTime.minute) -
                              (startTime.hour * 60 + startTime.minute);
                          final duration = oldDuration > 0 ? oldDuration : 60;

                          startTime = t;
                          // Auto-adjust end time to maintain duration
                          final newEndMinutes =
                              t.hour * 60 + t.minute + duration;
                          endTime = TimeOfDay(
                            hour: (newEndMinutes ~/ 60) % 24,
                            minute: newEndMinutes % 60,
                          );
                        });
                      }),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTimePicker('End', endTime, (t) {
                        setDialogState(() {
                          // Ensure end time is after start time
                          final startMinutes =
                              startTime.hour * 60 + startTime.minute;
                          final endMinutes = t.hour * 60 + t.minute;

                          if (endMinutes <= startMinutes) {
                            // Set end to at least 30 min after start
                            final newEndMinutes = startMinutes + 30;
                            endTime = TimeOfDay(
                              hour: (newEndMinutes ~/ 60) % 24,
                              minute: newEndMinutes % 60,
                            );
                          } else {
                            endTime = t;
                          }
                        });
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Quick Duration Buttons
                Text(
                  'Quick Duration',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildDurationChip('30m', 30, startTime, (newEnd) {
                      setDialogState(() => endTime = newEnd);
                    }),
                    const SizedBox(width: 8),
                    _buildDurationChip('1h', 60, startTime, (newEnd) {
                      setDialogState(() => endTime = newEnd);
                    }),
                    const SizedBox(width: 8),
                    _buildDurationChip('1.5h', 90, startTime, (newEnd) {
                      setDialogState(() => endTime = newEnd);
                    }),
                    const SizedBox(width: 8),
                    _buildDurationChip('2h', 120, startTime, (newEnd) {
                      setDialogState(() => endTime = newEnd);
                    }),
                  ],
                ),
                const SizedBox(height: 16),

                // Recurrence Options
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: recurrenceType,
                      dropdownColor: Colors.grey.shade800,
                      isExpanded: true,
                      icon: const Icon(Icons.repeat, color: Colors.grey),
                      items: [
                        DropdownMenuItem(
                          value: 'none',
                          child: Text(
                            'Does not repeat',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'daily',
                          child: Text(
                            'Repeat Daily',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'weekly',
                          child: Text(
                            'Repeat Weekly',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            recurrenceType = val;
                            if (recurrenceType == 'weekly' &&
                                recurrenceDays.isEmpty) {
                              recurrenceDays.add(_selectedDate.weekday);
                            }
                          });
                        }
                      },
                    ),
                  ),
                ),
                if (recurrenceType == 'weekly') ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    children: List.generate(7, (index) {
                      final day = index + 1; // 1=Mon
                      final isSelected = recurrenceDays.contains(day);
                      final labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            if (isSelected) {
                              if (recurrenceDays.length > 1) {
                                recurrenceDays.remove(day);
                              }
                            } else {
                              recurrenceDays.add(day);
                            }
                          });
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.accent
                                : Colors.grey.shade800,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: Colors.black, width: 2)
                                : null,
                          ),
                          child: Text(
                            labels[index],
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
                if (recurrenceType != 'none') ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate:
                            recurrenceEndTime ??
                            _selectedDate.add(const Duration(days: 30)),
                        firstDate: _selectedDate,
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setDialogState(() => recurrenceEndTime = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.event_available,
                            color: Colors.grey.shade500,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            recurrenceEndTime == null
                                ? 'Ends Never'
                                : 'Ends: ${DateFormat('MMM d, y').format(recurrenceEndTime!)}',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          if (recurrenceEndTime != null)
                            GestureDetector(
                              onTap: () => setDialogState(
                                () => recurrenceEndTime = null,
                              ),
                              child: Icon(
                                Icons.close,
                                color: Colors.grey,
                                size: 16,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Track on',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showQuickCreateTrackDialog(
                        context,
                        provider,
                        setDialogState,
                      ),
                      child: Text(
                        '+ CREATE NEW',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildTaskChip(
                      null,
                      linkedTaskId,
                      (v) => setDialogState(() => linkedTaskId = v),
                    ),
                    ...provider.tasks
                        .where((t) => t.id != TaskNode.unknownId)
                        .map(
                          (t) => _buildTaskChip(
                            t,
                            linkedTaskId,
                            (v) => setDialogState(() => linkedTaskId = v),
                          ),
                        ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Color',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: AppColors.palette
                      .map(
                        (c) => GestureDetector(
                          onTap: () => setDialogState(() => selectedColor = c),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: selectedColor == c
                                  ? Border.all(color: Colors.white, width: 2)
                                  : null,
                              boxShadow: selectedColor == c
                                  ? [
                                      BoxShadow(
                                        color: c.withOpacity(0.4),
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (isSaving) return;
                      if (titleController.text.isEmpty) return;

                      // Validate times
                      final startMinutes =
                          startTime.hour * 60 + startTime.minute;
                      final endMinutes = endTime.hour * 60 + endTime.minute;

                      // Check if end time is before or equal to start time
                      if (endMinutes <= startMinutes) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'End time must be after start time',
                            ),
                            backgroundColor: Colors.red.shade700,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                        return;
                      }

                      // Check minimum duration (5 minutes)
                      if (endMinutes - startMinutes < 5) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Event must be at least 5 minutes',
                            ),
                            backgroundColor: Colors.orange.shade700,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isSaving = true);

                      final start = DateTime(
                        _selectedDate.year,
                        _selectedDate.month,
                        _selectedDate.day,
                        startTime.hour,
                        startTime.minute,
                      );
                      final end = DateTime(
                        _selectedDate.year,
                        _selectedDate.month,
                        _selectedDate.day,
                        endTime.hour,
                        endTime.minute,
                      );

                      if (isEditing) {
                        bool updateSeries = true;

                        if (event.recurrenceType != 'none') {
                          // Ask user if they want to update instance or series
                          final result = await showDialog<String>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: Colors.grey.shade900,
                              title: const Text(
                                'Edit Recurring Event',
                                style: TextStyle(color: Colors.white),
                              ),
                              content: const Text(
                                'Do you want to update only this instance or the entire series?',
                                style: TextStyle(color: Colors.grey),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, 'cancel'),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, 'instance'),
                                  child: const Text(
                                    'This Instance',
                                    style: TextStyle(color: Colors.orange),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, 'series'),
                                  child: const Text(
                                    'All Events',
                                    style: TextStyle(color: Colors.blue),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (result == 'cancel' || result == null) {
                            setDialogState(() => isSaving = false);
                            return;
                          }

                          if (result == 'instance') {
                            updateSeries = false;
                            // 1. Exclude this date from master
                            await provider.toggleEventExclusion(
                              event.id,
                              event.startTime,
                            );

                            // 2. Create new single event
                            await provider.addEvent(
                              title: titleController.text,
                              description: descController.text.isEmpty
                                  ? null
                                  : descController.text,
                              startTime: start,
                              endTime: end,
                              colorValue: selectedColor.value,
                              linkedTaskId: linkedTaskId,
                              recurrenceType: 'none', // Single instance
                            );
                          }
                        }

                        if (updateSeries) {
                          await provider.updateEvent(
                            event.id,
                            title: titleController.text,
                            description: descController.text.isEmpty
                                ? null
                                : descController.text,
                            startTime: start,
                            endTime: end,
                            colorValue: selectedColor.value,
                            linkedTaskId: linkedTaskId,
                            recurrenceType: recurrenceType,
                            recurrenceEndTime: recurrenceEndTime,
                            recurrenceDays: recurrenceDays.toList(),
                          );
                        }
                      } else {
                        await provider.addEvent(
                          title: titleController.text,
                          description: descController.text.isEmpty
                              ? null
                              : descController.text,
                          startTime: start,
                          endTime: end,
                          colorValue: selectedColor.value,
                          linkedTaskId: linkedTaskId,
                          recurrenceType: recurrenceType,
                          recurrenceEndTime: recurrenceEndTime,
                          recurrenceDays: recurrenceDays.toList(),
                        );
                      }
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSaving
                          ? Colors.grey
                          : AppColors.accent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : Text(
                            isEditing ? 'SAVE' : 'CREATE',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskChip(
    dynamic task,
    String? selectedId,
    Function(String?) onSelect,
  ) {
    final isNone = task == null;
    final isSelected = isNone ? selectedId == null : selectedId == task.id;

    return GestureDetector(
      onTap: () => onSelect(isNone ? null : task.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.accent : Colors.grey.shade700,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isNone) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Color(task.colorValue),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              isNone ? 'None' : task.name,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.grey.shade400,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(
    String label,
    TimeOfDay time,
    Function(TimeOfDay) onPicked,
  ) {
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time,
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, color: Colors.grey.shade500, size: 16),
            const SizedBox(width: 8),
            Text(
              time.format(context),
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationChip(
    String label,
    int minutes,
    TimeOfDay startTime,
    Function(TimeOfDay) onSelect,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          final startMinutes = startTime.hour * 60 + startTime.minute;
          final endMinutes = startMinutes + minutes;
          final endHour = (endMinutes ~/ 60) % 24;
          final endMinute = endMinutes % 60;
          onSelect(TimeOfDay(hour: endHour, minute: endMinute));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.accent.withOpacity(0.3)),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade600),
      filled: true,
      fillColor: Colors.grey.shade800,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _showQuickCreateTrackDialog(
    BuildContext parentContext,
    TimeTrackerProvider provider,
    StateSetter setParentState,
  ) {
    final nameController = TextEditingController();
    Color selectedColor = AppColors.palette[0];
    String selectedType = 'DEEP WORK';
    final types = ['DEEP WORK', 'SHALLOW WORK', 'PERSONAL', 'WASTED'];

    showDialog(
      context: parentContext,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.grey.shade900,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Create New Track',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: _inputDecoration('Track name'),
                ),
                const SizedBox(height: 16),
                Text(
                  'Type',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: types
                      .map(
                        (t) => GestureDetector(
                          onTap: () => setDialogState(() => selectedType = t),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: selectedType == t
                                  ? AppColors.accent
                                  : Colors.grey.shade800,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              t,
                              style: TextStyle(
                                color: selectedType == t
                                    ? Colors.black
                                    : Colors.grey.shade400,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  'Color',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: AppColors.palette
                      .map(
                        (c) => GestureDetector(
                          onTap: () => setDialogState(() => selectedColor = c),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: selectedColor == c
                                  ? Border.all(color: Colors.white, width: 2)
                                  : null,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isEmpty) return;
                provider.addTask(
                  name: nameController.text,
                  colorValue: selectedColor.value,
                  baseType: selectedType,
                );
                Navigator.pop(context);
                setParentState(() {}); // Refresh parent dialog
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Create',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
