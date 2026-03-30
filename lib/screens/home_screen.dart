import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/time_tracking_provider.dart';
import '../models/task_node.dart';
import '../models/time_entry.dart';
import '../models/scheduled_event.dart';
import '../constants/colors.dart';
import 'manage_tasks_screen.dart';
import 'full_day_screen.dart';
import 'app_shell.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TimeTrackerProvider>(
      builder: (context, provider, child) {
        final currentEntry = provider.currentEntry;
        final currentTask = currentEntry != null
            ? provider.getTaskById(currentEntry.taskId)
            : null;

        final duration = currentEntry?.duration ?? Duration.zero;
        final durationStr =
            '${duration.inHours.toString().padLeft(2, '0')}:${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}';

        final isUnknown = currentTask?.id == TaskNode.unknownId;
        final selectableTasks = provider.tasks
            .where((t) => t.id != TaskNode.unknownId)
            .toList();

        final todayEntries = provider.getTodayEntries();
        final todayEvents = provider.getEventsForDate(DateTime.now());

        return SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildHeader(),
                const SizedBox(height: 20),
                _buildTimerCard(
                  provider: provider,
                  currentTask: currentTask,
                  durationStr: durationStr,
                  isUnknown: isUnknown,
                ),
                const SizedBox(height: 24),

                // Scheduled events for today
                if (todayEvents.isNotEmpty) ...[
                  _buildSectionHeader('TODAY\'S SCHEDULE', Icons.event),
                  const SizedBox(height: 12),
                  _buildScheduledEvents(todayEvents),
                  const SizedBox(height: 24),
                ],

                _buildSwitchTaskHeader(context),
                const SizedBox(height: 8),
                _buildTaskGrid(provider, selectableTasks, currentTask),
                const SizedBox(height: 20),
                Divider(color: Colors.white.withOpacity(0.08)),
                const SizedBox(height: 20),
                _buildQuickStats(provider),
                const SizedBox(height: 20),
                _buildTodayReality(provider, todayEntries),
                const SizedBox(height: 20),
                _buildFooter(),
                const SizedBox(height: 100), // Extra space for bottom nav
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final greeting = _getGreeting(now.hour);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('EEEE, MMM d').format(now),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
            image: const DecorationImage(
              image: AssetImage('assets/images/app_logo.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }

  String _getGreeting(int hour) {
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.accent, size: 16),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 11,
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildScheduledEvents(List<ScheduledEvent> events) {
    final now = DateTime.now();

    // Sort by start time
    final sorted = List<ScheduledEvent>.from(events)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    // Helper to check if event is active (happening right now)
    bool isEventActive(ScheduledEvent e) {
      var effectiveEnd = e.endTime;
      if (effectiveEnd.isBefore(e.startTime)) {
        effectiveEnd = effectiveEnd.add(const Duration(days: 1));
      }
      // Event is active if it has started AND hasn't ended yet
      return !e.startTime.isAfter(now) && effectiveEnd.isAfter(now);
    }

    // Separate active (happening now) and upcoming events
    final activeEvents = sorted.where((e) => isEventActive(e)).toList();

    final upcomingEvents = sorted.where((e) {
      // Upcoming = starts after now
      return e.startTime.isAfter(now);
    }).toList();

    // Show all active events as cards, next 3 upcoming as bubbles
    final bubbleEvents = upcomingEvents.take(3).toList();

    // If no active events, show nothing for cards section (bubbles only)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // All active event cards (currently happening)
        if (activeEvents.isNotEmpty)
          ...activeEvents.map((event) => _buildEventCard(event, now)),

        // Mini bubbles for next 3 upcoming events
        if (bubbleEvents.isNotEmpty) ...[
          if (activeEvents.isNotEmpty) const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: bubbleEvents.map((e) => _buildMiniBubble(e)).toList(),
          ),
        ],

        // See full schedule link
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            // Navigate to Calendar tab (index 1)
            AppShell.shellKey.currentState?.navigateTo(1);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'See full schedule',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward, color: AppColors.accent, size: 14),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard(ScheduledEvent event, DateTime now) {
    final startTimeStr = DateFormat('h:mm a').format(event.startTime);
    final endTimeStr = DateFormat('h:mm a').format(event.endTime);

    var effectiveEndTime = event.endTime;
    if (effectiveEndTime.isBefore(event.startTime)) {
      effectiveEndTime = effectiveEndTime.add(const Duration(days: 1));
    }

    final isOngoing =
        now.isAfter(event.startTime) && now.isBefore(effectiveEndTime);
    final eventColor = Color(event.colorValue);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time Column
          SizedBox(
            width: 55,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  startTimeStr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  endTimeStr,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Event Card
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isOngoing
                    ? eventColor.withOpacity(0.15)
                    : Colors.grey.shade900,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isOngoing
                      ? eventColor.withOpacity(0.4)
                      : Colors.white.withOpacity(0.05),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 28,
                      decoration: BoxDecoration(
                        color: eventColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        event.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isOngoing)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: eventColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'NOW',
                          style: TextStyle(
                            color: eventColor,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBubble(ScheduledEvent event) {
    final eventColor = Color(event.colorValue);
    final timeStr = DateFormat('h:mm').format(event.startTime);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: eventColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: eventColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: eventColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$timeStr · ${event.title}',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTimerCard({
    required TimeTrackerProvider provider,
    required TaskNode? currentTask,
    required String durationStr,
    required bool isUnknown,
  }) {
    final taskColor = currentTask?.color ?? AppColors.unknown;

    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1E1E1E), // Flatter, less intense dark
              const Color(0xFF121212),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: taskColor.withValues(alpha: 0.15), // Reduced opacity
            width: 1,
          ),
          // Removed outer box shadow for cleaner look
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
                    color: taskColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: taskColor.withValues(alpha: 0.3), // Reduced glow
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'TRACKING',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 10,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _showAddNoteDialog(context, provider),
                  child: Icon(
                    Icons.edit_note,
                    color: Colors.grey.shade500,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              currentTask?.id == TaskNode.unknownId
                  ? 'Select Task from sidebar'
                  : (currentTask?.name ?? 'Select Task from sidebar'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              durationStr,
              style: TextStyle(
                color: taskColor,
                fontSize: 44,
                fontWeight: FontWeight.w200,
                fontFeatures: const [FontFeature.tabularFigures()],
                letterSpacing: 2,
                shadows: [
                  Shadow(
                    color: taskColor.withValues(alpha: 0.2), // Reduced glow
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(TimeTrackerProvider provider) {
    final todayEntries = provider.getTodayEntries();
    Duration deepWork = Duration.zero;
    Duration wasted = Duration.zero;

    for (var entry in todayEntries) {
      final task = provider.getTaskById(entry.taskId);
      if (task?.baseType == 'WASTED') {
        wasted += entry.duration;
      } else if (task?.baseType == 'DEEP WORK') {
        deepWork += entry.duration;
      }
    }

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'FOCUS',
            _formatDuration(deepWork),
            AppColors.accent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            'WASTED',
            _formatDuration(wasted),
            AppColors.unknown,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            'SWITCHES',
            '${todayEntries.length}',
            Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    return '${d.inMinutes}m';
  }

  Widget _buildSwitchTaskHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'SWITCH TASK',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 10,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ManageTasksScreen(),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.tune, color: Colors.grey.shade500, size: 12),
                const SizedBox(width: 4),
                Text(
                  'Manage',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskGrid(
    TimeTrackerProvider provider,
    List<TaskNode> selectableTasks,
    TaskNode? currentTask,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.6,
      ),
      itemCount: selectableTasks.length,
      itemBuilder: (context, index) {
        final task = selectableTasks[index];
        final isSelected = task.id == currentTask?.id;

        return GestureDetector(
          onTap: () => provider.switchTask(task.id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? task.color.withValues(alpha: 0.12)
                  : const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? task.color.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Task name with color indicator
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: task.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        task.name,
                        style: TextStyle(
                          color: isSelected ? task.color : Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check, color: task.color, size: 12),
                  ],
                ),
                // Category
                if (task.category.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 10, top: 2),
                    child: Text(
                      task.category,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 9,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTodayReality(
    TimeTrackerProvider provider,
    List<TimeEntry> entries,
  ) {
    if (entries.isEmpty) return const SizedBox.shrink();

    final entriesToShow = entries.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "TODAY'S REALITY",
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 11,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (entries.length > 5)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FullDayScreen(),
                    ),
                  );
                },
                child: Text(
                  'VIEW ALL',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 10,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ...entriesToShow.map((entry) {
          final task = provider.getTaskById(entry.taskId);
          final timeStr = DateFormat('HH:mm').format(entry.startTime);
          final durationMin = entry.duration.inMinutes;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey.shade900,
                  Colors.grey.shade900.withValues(alpha: 0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.02)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: (task?.color ?? Colors.grey).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: task?.color ?? Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  timeStr,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    task?.name ?? 'Unknown',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${durationMin}m',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Text(
        'CLAZZY • 2ND-LVL TIME LOG',
        style: TextStyle(
          color: Colors.grey.shade700,
          fontSize: 9,
          letterSpacing: 2,
        ),
      ),
    );
  }

  void _showAddNoteDialog(BuildContext context, TimeTrackerProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Add Note',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'What are you working on?',
            hintStyle: TextStyle(color: Colors.grey.shade600),
            filled: true,
            fillColor: Colors.grey.shade800,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty && provider.currentEntry != null) {
                provider.currentEntry!.note = controller.text;
                provider.currentEntry!.save();
              }
              Navigator.pop(context);
            },
            child: const Text(
              'Save',
              style: TextStyle(color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}
