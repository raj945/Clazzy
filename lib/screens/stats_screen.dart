import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/time_tracking_provider.dart';
import '../models/time_entry.dart';
import 'monthly_analytics_screen.dart';
import 'weekly_analytics_screen.dart';

import '../constants/colors.dart';
import '../services/notification_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TimeTrackerProvider>(context);
    // Filter history for selected date
    final dayEntries = provider.history.where((e) {
      return DateFormat('yyyy-MM-dd').format(e.startTime) ==
          DateFormat('yyyy-MM-dd').format(_selectedDate);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'ANALYTICS',
          style: TextStyle(
            fontSize: 22,
            letterSpacing: 1.0,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary, // Ensure visible on transparent
          ),
        ),
        centerTitle: false, // Consistent Left Alignment
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Test Notification Button
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.notifications_outlined,
                color: AppColors.accent,
                size: 20,
              ),
            ),
            color: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade800),
            ),
            offset: const Offset(0, 50),
            onSelected: (value) => _showTestNotification(context, value),
            itemBuilder: (context) => [
              _buildNotificationMenuItem(
                'calendar_event',
                Icons.calendar_today,
                'Calendar Event',
                'Test calendar reminder',
                AppColors.accent,
              ),
              _buildNotificationMenuItem(
                'switch_task',
                Icons.swap_horiz,
                'Switch Task',
                'Test task switch prompt',
                Colors.orangeAccent,
              ),
              _buildNotificationMenuItem(
                'goal_reminder',
                Icons.flag_outlined,
                'Goal Reminder',
                'Test goal progress alert',
                Colors.greenAccent,
              ),
              _buildNotificationMenuItem(
                'break_reminder',
                Icons.coffee_outlined,
                'Break Reminder',
                'Test break notification',
                Colors.purpleAccent,
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],

        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'RAW VIEW'),
            Tab(text: 'WEEKLY'),
            Tab(text: 'MONTHLY'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRawView(context, provider, dayEntries),
          const WeeklyAnalyticsScreen(),
          const MonthlyAnalyticsScreen(),
        ],
      ),
    );
  }

  // Build popup menu item for notification types
  PopupMenuItem<String> _buildNotificationMenuItem(
    String value,
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Show test in-app notification
  void _showTestNotification(BuildContext context, String type) {
    // Notification content based on type
    String title;
    String body;
    IconData icon;
    Color color;
    List<String>? actions;

    switch (type) {
      case 'calendar_event':
        title = 'Upcoming Event';
        body = 'Team Standup starts in 5 minutes';
        icon = Icons.calendar_today;
        color = AppColors.accent;
        actions = ['Join Now', 'Snooze 5m'];
        break;
      case 'switch_task':
        title = 'Time to Switch';
        body =
            'You\'ve been on "Deep Work" for 90 min. Consider a break or switch.';
        icon = Icons.swap_horiz;
        color = Colors.orangeAccent;
        actions = ['Switch Task', 'Continue'];
        break;
      case 'goal_reminder':
        title = 'Goal Progress';
        body = 'You\'re 80% through your daily focus goal. Keep going!';
        icon = Icons.flag_outlined;
        color = Colors.greenAccent;
        actions = ['View Goals', 'Dismiss'];
        break;
      case 'break_reminder':
        title = 'Take a Break';
        body = 'You\'ve been working for 2 hours. Time to stretch!';
        icon = Icons.coffee_outlined;
        color = Colors.purpleAccent;
        actions = ['Start Break', 'Later'];
        break;
      default:
        title = 'Notification';
        body = 'This is a test notification';
        icon = Icons.notifications;
        color = Colors.grey;
        actions = ['OK'];
    }

    NotificationService().show(
      context: context,
      title: title,
      body: body,
      icon: icon,
      color: color,
      actions: actions,
    );
  }

  Widget _buildRawView(
    BuildContext context,
    TimeTrackerProvider provider,
    List<TimeEntry> dayEntries,
  ) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.grey),
                onPressed: () => _changeDate(-1),
              ),
              Text(
                DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.grey),
                onPressed: () => _changeDate(1),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // 1. DAY TIMELINE
          _buildSectionTitle('1. DAY TIMELINE (REALITY)'),
          const SizedBox(height: 16),
          // Scrollable Timeline Container
          Container(
            height: 400, // Visible window
            decoration: BoxDecoration(
              color: Colors.grey.shade900.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: SingleChildScrollView(
              child: _buildDayTimeline(dayEntries, provider),
            ),
          ),
          const SizedBox(height: 40),

          // 2. TIME DISTRIBUTION (ABSOLUTE)
          _buildSectionTitle('2. WHERE TIME WENT'),
          const SizedBox(height: 16),
          _buildTimeDistribution(dayEntries, provider),
          const SizedBox(height: 30),
          Divider(color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 30),

          // 3. TASK BREAKDOWN
          _buildSectionTitle('3. TASK BREAKDOWN'),
          const SizedBox(height: 16),
          _buildTaskBreakdown(dayEntries, provider),
          const SizedBox(height: 40),

          // 4. EVENT PERFORMANCE
          _buildSectionTitle('4. EVENT PERFORMANCE'),
          const SizedBox(height: 16),
          _buildEventTimelineAnalysis(dayEntries, provider),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.grey.shade500,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  // --- 1. DAY TIMELINE ---
  Widget _buildDayTimeline(
    List<TimeEntry> entries,
    TimeTrackerProvider provider,
  ) {
    // 00:00 - 24:00 Vertical Timeline
    // Fixed height: 1200px -> 50px per hour
    const double totalHeight = 1200;
    const double hourHeight = totalHeight / 24;

    return SizedBox(
      height: totalHeight,
      width: double.infinity,
      child: Stack(
        children: [
          // Grid Lines (Hours)
          for (int i = 0; i <= 24; i++)
            Positioned(
              top: i * hourHeight,
              left: 0,
              right: 0,
              child: Container(
                height: 1,
                color: i % 6 == 0
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.03),
              ),
            ),

          // Time Labels (Left Side)
          for (int i = 0; i <= 24; i++)
            Positioned(
              top: (i * hourHeight) - 6,
              left: 8,
              child: Text(
                '${i.toString().padLeft(2, '0')}:00',
                style: TextStyle(
                  color: i % 6 == 0
                      ? Colors.grey.shade400
                      : Colors.grey.shade700,
                  fontSize: 10,
                  fontWeight: i % 6 == 0 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),

          // Activity Blocks
          ...entries.map((e) {
            final startOffset =
                (e.startTime.hour * 60 + e.startTime.minute) /
                1440 *
                totalHeight;
            // Handle cross-day? Assuming single day for now as per "Day View"
            final endMinutes = e.endTime == null
                ? (DateTime.now().hour * 60 + DateTime.now().minute)
                : (e.endTime!.hour * 60 + e.endTime!.minute);

            // Fix: If endTime is earlier than startTime (spanning midnight), clip it or ignore for this day view.
            // Simple clip:
            final safeEndMinutes =
                endMinutes < (e.startTime.hour * 60 + e.startTime.minute)
                ? 1440
                : endMinutes;

            final durationMinutes =
                safeEndMinutes - (e.startTime.hour * 60 + e.startTime.minute);
            final height = (durationMinutes / 1440) * totalHeight;

            final task = provider.getTaskById(e.taskId);

            return Positioned(
              top: startOffset,
              left: 50, // Offset for time labels
              right: 10,
              height: height > 1 ? height : 1, // Min height 1
              child: Container(
                decoration: BoxDecoration(
                  color:
                      task?.color.withValues(alpha: 0.9) ??
                      Colors.grey.shade700,
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                alignment: Alignment.centerLeft,
                // Only show text if block is tall enough
                child: height > 15
                    ? Text(
                        task?.name ?? 'Unknown',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
              ),
            );
          }),
        ],
      ),
    );
  }

  // --- 2. TIME DISTRIBUTION ---
  Widget _buildTimeDistribution(
    List<TimeEntry> entries,
    TimeTrackerProvider provider,
  ) {
    if (entries.isEmpty) {
      return const Center(
        child: Text(
          'No data for this day',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Group by BaseType (which approximates categories like Deep Work, etc.)
    // If baseType isn't detailed enough, we can map Category.
    // Assuming TaskNode has `isCategory` or `category` field that helps.
    // For now, let's group by `task.category` or ID.
    // Actually, prompt asks for: Deep Work, Shallow Work, Personal, Wasted, Unassigned.
    // We'll infer these from task attributes or baseType.

    final Map<String, int> distribution = {
      'Deep Work': 0,
      'Shallow Work': 0,
      'Personal': 0,
      'Wasted': 0,
      'Unassigned': 0,
    };

    for (var e in entries) {
      final task = provider.getTaskById(e.taskId);
      final duration =
          e.duration.inMinutes; // This getter handles null endTime (uses now)

      if (task == null) {
        distribution['Unassigned'] = (distribution['Unassigned']!) + duration;
        continue;
      }

      // Basic Classification Logic
      // Users might customize this, but we'll infer for now
      final String type = task.baseType.toUpperCase();
      if (type == 'DEEP WORK' || type == 'FOCUS') {
        distribution['Deep Work'] = (distribution['Deep Work']!) + duration;
      } else if (type == 'WASTED' || type == 'LEISURE') {
        distribution['Wasted'] = (distribution['Wasted']!) + duration;
      } else if (type == 'PERSONAL' || type == 'HEALTH') {
        distribution['Personal'] = (distribution['Personal']!) + duration;
      } else {
        distribution['Shallow Work'] =
            (distribution['Shallow Work']!) + duration;
      }
    }

    // Stacked Bar
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: distribution.entries.map((entry) {
              if (entry.value == 0) return const SizedBox.shrink();
              final flex = entry.value;
              Color color;
              switch (entry.key) {
                case 'Deep Work':
                  color = AppColors.accent;
                  break;
                case 'Wasted':
                  color = Colors.redAccent;
                  break;
                case 'Personal':
                  color = Colors.greenAccent;
                  break;
                case 'Unassigned':
                  color = Colors.grey;
                  break;
                default:
                  color = Colors.blueAccent;
              }

              return Expanded(
                flex: flex,
                child: Tooltip(
                  message: '${entry.key}: ${_formatMin(entry.value)}',
                  child: Container(height: 30, color: color),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: distribution.entries.where((e) => e.value > 0).map((e) {
              Color color;
              switch (e.key) {
                case 'Deep Work':
                  color = AppColors.accent;
                  break;
                case 'Wasted':
                  color = Colors.redAccent;
                  break;
                case 'Personal':
                  color = Colors.greenAccent;
                  break;
                case 'Unassigned':
                  color = Colors.grey;
                  break;
                default:
                  color = Colors.blueAccent;
              }
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 12, height: 12, color: color),
                  const SizedBox(width: 8),
                  Text(
                    '${e.key}: ${_formatMin(e.value)}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // --- 3. TASK BREAKDOWN ---
  Widget _buildTaskBreakdown(
    List<TimeEntry> entries,
    TimeTrackerProvider provider,
  ) {
    if (entries.isEmpty) {
      return const Center(
        child: Text('No data', style: TextStyle(color: Colors.grey)),
      );
    }

    // Group by Task
    final Map<String, _TaskStat> stats = {};

    for (var e in entries) {
      stats
          .putIfAbsent(e.taskId, () => _TaskStat(taskId: e.taskId))
          .add(e.duration);
    }

    final sortedStats = stats.values.toList()
      ..sort((a, b) => b.totalMinutes.compareTo(a.totalMinutes));

    return Column(
      children: sortedStats.map((stat) {
        final task = provider.getTaskById(stat.taskId);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 24,
                color: task?.color ?? Colors.grey,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  task?.name ?? 'Unknown Task',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatMin(stat.totalMinutes),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${stat.sessionCount} sessions',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // --- 4. EVENT PERFORMANCE (VERTICAL) ---
  Widget _buildEventTimelineAnalysis(
    List<TimeEntry> entries,
    TimeTrackerProvider provider,
  ) {
    const double totalHeight = 1000.0; // Fixed height for 24h vertical view

    return Container(
      height: totalHeight + 50, // + header/padding
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          // Header Row
          Row(
            children: [
              const SizedBox(width: 50), // Time axis gap
              Expanded(
                child: Text(
                  'PLANNED',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'EXECUTED',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final colWidth =
                    (constraints.maxWidth - 60) /
                    2; // Subtract time width + gaps

                final dayStart = DateTime(
                  _selectedDate.year,
                  _selectedDate.month,
                  _selectedDate.day,
                );
                final dayEnd = dayStart.add(const Duration(days: 1));

                // 1. Grid Lines & Time Labels
                List<Widget> gridLayers = [];
                for (int i = 0; i <= 24; i++) {
                  final top = (i * 60 / 1440.0) * totalHeight;
                  // Label
                  gridLayers.add(
                    Positioned(
                      top: top - 6,
                      left: 0,
                      width: 45,
                      child: Text(
                        '$i:00',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  );
                  // Line
                  gridLayers.add(
                    Positioned(
                      top: top,
                      left: 50,
                      right: 0,
                      child: Container(
                        height: 1,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  );
                }

                // 2. Planned Segments
                List<Widget> plannedLayers = [];
                for (var e in provider.events) {
                  var eStart = e.startTime;
                  var eEnd = e.endTime.isBefore(e.startTime)
                      ? e.endTime.add(const Duration(days: 1))
                      : e.endTime;

                  // Clip
                  if (eEnd.isBefore(dayStart) || eStart.isAfter(dayEnd)) {
                    continue;
                  }
                  final start = eStart.isBefore(dayStart) ? dayStart : eStart;
                  final end = eEnd.isAfter(dayEnd) ? dayEnd : eEnd;
                  final durationMin = end.difference(start).inMinutes;
                  if (durationMin <= 0) continue;

                  final startOffset = start.difference(dayStart).inMinutes;
                  final top = (startOffset / 1440.0) * totalHeight;
                  final height = (durationMin / 1440.0) * totalHeight;

                  final task = e.linkedTaskId != null
                      ? provider.getTaskById(e.linkedTaskId!)
                      : null;
                  final color = task?.color ?? Colors.grey;

                  plannedLayers.add(
                    Positioned(
                      top: top,
                      left: 54, // After time labels
                      width: colWidth - 4, // Slight gap
                      height: height,
                      child: Container(
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.3),
                          border: Border.all(color: color.withOpacity(0.8)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
                        child: height < 16
                            ? null
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    e.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (height > 35)
                                    Text(
                                      '${_formatTime(start)} - ${_formatTime(end)}',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 9,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                      ),
                    ),
                  );
                }

                // 3. Executed Segments
                List<Widget> executedLayers = [];
                for (var e in entries) {
                  final startMin = e.startTime.hour * 60 + e.startTime.minute;
                  var eEnd = e.endTime ?? DateTime.now();
                  if (eEnd.isBefore(e.startTime)) {
                    eEnd = eEnd.add(const Duration(days: 1));
                  }

                  var duration = eEnd.difference(e.startTime).inMinutes;
                  if (startMin + duration > 1440) duration = 1440 - startMin;
                  if (duration <= 0) continue;

                  final top = (startMin / 1440.0) * totalHeight;
                  final height = (duration / 1440.0) * totalHeight;

                  final task = provider.getTaskById(e.taskId);
                  final color = task?.color ?? Colors.grey;

                  executedLayers.add(
                    Positioned(
                      top: top,
                      left: 54 + colWidth + 4, // Second column
                      width: colWidth - 4,
                      height: height,
                      child: Container(
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
                        child: height < 16
                            ? null
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    task?.name ?? '',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 2,
                                          color: Colors.black,
                                        ),
                                      ],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (height > 35)
                                    Text(
                                      '${_formatTime(e.startTime)} - ${_formatTime(eEnd)}',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 9,
                                        shadows: [
                                          Shadow(
                                            blurRadius: 2,
                                            color: Colors.black,
                                          ),
                                        ],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                      ),
                    ),
                  );
                }

                return SizedBox(
                  height: totalHeight,
                  child: Stack(
                    children: [
                      ...gridLayers,
                      ...plannedLayers,
                      ...executedLayers,
                      // Center Divider
                      Positioned(
                        top: 0,
                        bottom: 0,
                        left: 54 + colWidth,
                        child: Container(
                          width: 1,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _TaskStat {
  final String taskId;
  int totalMinutes = 0;
  int sessionCount = 0;

  _TaskStat({required this.taskId});

  void add(Duration d) {
    totalMinutes += d.inMinutes;
    sessionCount++;
  }
}

String _formatMin(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h > 0) return '${h}h ${m}m';
  return '${m}m';
}
