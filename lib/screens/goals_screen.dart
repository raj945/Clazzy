import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/time_tracking_provider.dart';
import '../models/goal.dart';
import '../models/deadline_item.dart';
import '../models/scheduled_event.dart';
import '../constants/colors.dart';
import '../models/time_entry.dart';
import 'package:intl/intl.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final Map<String, bool> _expandedGroups = {};

  @override
  Widget build(BuildContext context) {
    return Consumer<TimeTrackerProvider>(
      builder: (context, provider, child) {
        final goals = provider.goals;
        final timeGoals = goals
            .where((g) => g.contributionType == 'time')
            .toList();
        final attendanceGoals = goals
            .where((g) => g.contributionType == 'event')
            .toList();
        final deadlines = provider.deadlines;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  MediaQuery.of(context).padding.top + 16,
                  20,
                  8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TRACKER',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('MMMM d, yyyy').format(DateTime.now()),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(0, 20, 0, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Daily Goals
                      _buildGoalsSection(provider, timeGoals),
                      const SizedBox(height: 32),

                      // 2. Attendance / Events
                      _buildAttendanceSection(provider, attendanceGoals),
                      // Attendance section controls its own spacing/padding but we need consistent gap?
                      // _buildAttendanceSection will now include bottom padding or we add it here?
                      // _buildGoalsSection doesn't return bottom padding.
                      // I'll leave SizedBox(height: 32) after it if it renders anything.
                      // Since it ALWAYS renders (empty or not), we need spacing.
                      // But _buildAttendanceSection in my next edit will return Column.

                      // 3. Deadlines
                      _buildDeadlinesSection(provider, deadlines),
                    ],
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 90),
            child: FloatingActionButton(
              onPressed: () => _showAddMenu(context, provider),
              backgroundColor: AppColors.accent,
              child: const Icon(Icons.add, color: Colors.black),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeadlinesSection(
    TimeTrackerProvider provider,
    List<DeadlineItem> deadlines,
  ) {
    final now = DateTime.now();
    // Normalize to start of day for accurate date comparisons
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));

    final pending = deadlines.where((d) => d.status != 'completed').toList();
    final completed = deadlines.where((d) => d.status == 'completed').toList();

    final overdue = pending.where((d) {
      final dueStart = DateTime(d.dueDate.year, d.dueDate.month, d.dueDate.day);
      return dueStart.isBefore(todayStart);
    }).toList();
    final today = pending.where((d) {
      final dueStart = DateTime(d.dueDate.year, d.dueDate.month, d.dueDate.day);
      return dueStart.isAtSameMomentAs(todayStart);
    }).toList();
    final tomorrow = pending.where((d) {
      final dueStart = DateTime(d.dueDate.year, d.dueDate.month, d.dueDate.day);
      return dueStart.isAtSameMomentAs(tomorrowStart);
    }).toList();
    final thisWeek = pending.where((d) {
      final dueStart = DateTime(d.dueDate.year, d.dueDate.month, d.dueDate.day);
      final diff = dueStart.difference(todayStart).inDays;
      return diff > 1 && diff <= 7;
    }).toList();
    final later = pending.where((d) {
      final dueStart = DateTime(d.dueDate.year, d.dueDate.month, d.dueDate.day);
      return dueStart.difference(todayStart).inDays > 7;
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'DEADLINES',
            Icons.flag_outlined,
            deadlines.length,
          ),
          const SizedBox(height: 12),
          if (deadlines.isEmpty)
            _buildEmptyCard('No deadlines', 'Tap flag to add one')
          else ...[
            if (overdue.isNotEmpty)
              _buildDeadlineGroup('OVERDUE', overdue, Colors.red, provider),
            if (today.isNotEmpty)
              _buildDeadlineGroup('DUE TODAY', today, Colors.orange, provider),
            if (tomorrow.isNotEmpty)
              _buildDeadlineGroup(
                'DUE TOMORROW',
                tomorrow,
                AppColors.accent,
                provider,
              ),
            if (thisWeek.isNotEmpty)
              _buildDeadlineGroup('THIS WEEK', thisWeek, Colors.blue, provider),
            if (later.isNotEmpty)
              _buildDeadlineGroup(
                'LATER',
                later,
                Colors.purple,
                provider,
                onShowFull: () => _showDeadlineListSheet(
                  context,
                  'LATER',
                  'LATER',
                  Colors.purple,
                ),
              ),
            if (completed.isNotEmpty)
              GestureDetector(
                onTap: () => _showDeadlineListSheet(
                  context,
                  'COMPLETED',
                  'COMPLETED',
                  Colors.green,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 24, bottom: 8),
                  child: Row(
                    children: [
                      Text(
                        'COMPLETED (${completed.length})',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildGoalsSection(TimeTrackerProvider provider, List<Goal> goals) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('GOALS', Icons.track_changes, goals.length),
          const SizedBox(height: 12),
          if (goals.isEmpty)
            _buildEmptyCard('No goals yet', 'Set goals to track consistency')
          else
            ...goals.map((g) => _buildGoalCard(provider, g)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, int count) {
    return Row(
      children: [
        Icon(icon, color: AppColors.accent, size: 16),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyCard(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.grey.shade600, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlineGroup(
    String label,
    List<DeadlineItem> items,
    Color color,
    TimeTrackerProvider provider, {
    VoidCallback? onShowFull,
  }) {
    // Determine display mode based on label
    final isFullDisplay =
        label == 'OVERDUE' || label == 'DUE TODAY' || label == 'DUE TOMORROW';
    final isThisWeek = label == 'THIS WEEK';
    final isLater = label == 'LATER';
    final isExpanded = _expandedGroups[label] ?? false;

    List<DeadlineItem> cardItems = [];
    List<DeadlineItem> bubbleItems = [];
    bool showMoreButton = false;

    if (isFullDisplay) {
      cardItems = items;
    } else if (isThisWeek) {
      if (isExpanded) {
        cardItems = items; // Show all as cards when expanded
        showMoreButton = true;
      } else {
        cardItems = items.take(2).toList();
        bubbleItems = items.skip(2).toList();
        if (items.length > 2) showMoreButton = true;
      }
    } else if (isLater) {
      // ALWAYS show 5 bubbles for LATER, the rest are accessed via "Show full" header
      bubbleItems = items.take(5).toList();
      // showMoreButton is not needed at bottom if we have header link,
      // OR we can keep "+ X more" to visually indicate overflow
      if (items.length > 5) showMoreButton = true;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              if (onShowFull != null)
                GestureDetector(
                  onTap: onShowFull,
                  child: Text(
                    'Show full',
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Card items
        ...cardItems.map((d) => _buildDeadlineCard(d, color, provider)),
        // Bubble items
        if (bubbleItems.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: bubbleItems
                .map((d) => _buildDeadlineBubble(d, color, provider))
                .toList(),
          ),
        ],
        // Show Full / Show Less button (Only for This Week expansion or LATER overflow count text)
        if (showMoreButton) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              if (onShowFull != null) {
                onShowFull();
              } else {
                setState(() {
                  _expandedGroups[label] = !isExpanded;
                });
              }
            },
            child: Text(
              onShowFull != null
                  ? '+${items.length - 5} more'
                  : (isExpanded ? 'Show less' : 'See full list'),
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showDeadlineListSheet(
    BuildContext context,
    String title,
    String groupType,
    Color color,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Consumer<TimeTrackerProvider>(
            builder: (context, provider, _) {
              final now = DateTime.now();
              List<DeadlineItem> items = [];
              if (groupType == 'COMPLETED') {
                items = provider.deadlines
                    .where((d) => d.status == 'completed')
                    .toList();
              } else if (groupType == 'LATER') {
                items = provider.deadlines
                    .where(
                      (d) =>
                          d.status != 'completed' &&
                          d.dueDate.difference(now).inDays > 7,
                    )
                    .toList();
              }

              if (items.isEmpty) {
                return const Center(
                  child: Text("No items", style: TextStyle(color: Colors.grey)),
                );
              }

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: items.length,
                      itemBuilder: (context, index) =>
                          _buildDeadlineCard(items[index], color, provider),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDeadlineBubble(
    DeadlineItem deadline,
    Color color,
    TimeTrackerProvider provider,
  ) {
    return GestureDetector(
      onTap: () => _showDeadlineDetailsDialog(context, provider, deadline),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              deadline.title,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeadlineCard(
    DeadlineItem deadline,
    Color accentColor,
    TimeTrackerProvider provider,
  ) {
    return Dismissible(
      key: Key(deadline.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      confirmDismiss: (direction) async {
        // Store for undo
        final deletedDeadline = deadline;
        provider.deleteDeadline(deadline.id);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Deadline deleted'),
            action: SnackBarAction(
              label: 'UNDO',
              textColor: AppColors.accent,
              onPressed: () {
                provider.addDeadline(deletedDeadline);
              },
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.grey.shade900,
          ),
        );
        return false; // We already deleted it
      },
      child: GestureDetector(
        onTap: () => _showDeadlineDetailsDialog(context, provider, deadline),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accentColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () async {
                  deadline.status = deadline.status == 'completed'
                      ? 'todo'
                      : 'completed';
                  await provider.updateDeadline(deadline);
                },
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: accentColor, width: 2),
                    color: deadline.status == 'completed'
                        ? accentColor
                        : Colors.transparent,
                  ),
                  child: deadline.status == 'completed'
                      ? const Icon(Icons.check, size: 14, color: Colors.black)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: TextStyle(
                        color: deadline.status == 'completed'
                            ? Colors.grey.shade600
                            : AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        decoration: deadline.status == 'completed'
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                      child: Text(deadline.title),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 10,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM d, yyyy').format(deadline.dueDate),
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeadlineDetailsDialog(
    BuildContext context,
    TimeTrackerProvider provider,
    DeadlineItem deadline,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          deadline.title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMM d, yyyy').format(deadline.dueDate),
                  style: TextStyle(color: Colors.grey.shade400),
                ),
              ],
            ),
            if (deadline.notes != null && deadline.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'NOTES',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                deadline.notes!,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Status:', style: TextStyle(color: Colors.grey.shade500)),
                GestureDetector(
                  onTap: () {
                    deadline.status = deadline.status == 'completed'
                        ? 'todo'
                        : 'completed';
                    provider.updateDeadline(deadline);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: deadline.status == 'completed'
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: deadline.status == 'completed'
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                    child: Text(
                      deadline.status == 'completed' ? 'COMPLETED' : 'PENDING',
                      style: TextStyle(
                        color: deadline.status == 'completed'
                            ? Colors.green
                            : Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: Colors.grey.shade600)),
          ),
        ],
      ),
    );
  }

  void _showAddDeadlineDialog(
    BuildContext context,
    TimeTrackerProvider provider,
  ) {
    final titleController = TextEditingController();
    final notesController = TextEditingController(); // Added notes controller
    DateTime dueDate = DateTime.now().add(const Duration(days: 1));

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'New Deadline',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'e.g. Submit assignment',
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  filled: true,
                  fillColor: Colors.grey.shade800,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Notes field
              TextField(
                controller: notesController,
                style: const TextStyle(color: AppColors.textPrimary),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Notes (optional)',
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  filled: true,
                  fillColor: Colors.grey.shade800,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Due Date',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: dueDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setDialogState(() => dueDate = picked);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    DateFormat('EEEE, MMM d, yyyy').format(dueDate),
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isEmpty) return;
                    provider.addDeadline(
                      DeadlineItem(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: titleController.text,
                        dueDate: dueDate,
                        taskCategoryId: '',
                        notes: notesController.text.isEmpty
                            ? null
                            : notesController.text,
                      ),
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'CREATE DEADLINE',
                    style: TextStyle(
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
    );
  }

  Widget _buildGoalCard(TimeTrackerProvider provider, Goal goal) {
    final progress = provider.getGoalProgress(goal);
    final streak = provider.getGoalStreak(goal);
    final progressPercent = (progress * 100).clamp(0, 100).round();

    // Get the tracked task for display
    final trackedTask = goal.taskId != null
        ? provider.getTaskById(goal.taskId!)
        : null;
    final trackingLabel = trackedTask?.name ?? 'Any Task';
    final trackingCategory = trackedTask?.category ?? '';

    return Dismissible(
      key: Key(goal.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      confirmDismiss: (direction) async {
        // Show undo snackbar
        final deleted = await _deleteGoalWithUndo(context, provider, goal);
        return deleted;
      },
      child: GestureDetector(
        onTap: () => _showGoalAnalysisDialog(context, provider, goal),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey.shade900,
                Colors.grey.shade900.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: progress >= 1.0
                  ? AppColors.success.withValues(alpha: 0.5)
                  : Color(goal.colorValue).withValues(alpha: 0.2),
            ),
            boxShadow: progress >= 1.0
                ? [
                    BoxShadow(
                      color: AppColors.success.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Circular Progress Indicator
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          strokeWidth: 3,
                          backgroundColor: Colors.grey.shade800,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progress >= 1.0
                                ? AppColors.success
                                : Color(goal.colorValue),
                          ),
                        ),
                        Icon(
                          _getGoalIcon(goal.contributionType),
                          color: Color(goal.colorValue),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Tracking Label
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Color(
                                  goal.colorValue,
                                ).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.track_changes,
                                    size: 10,
                                    color: Color(goal.colorValue),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    trackingLabel,
                                    style: TextStyle(
                                      color: Color(goal.colorValue),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (trackingCategory.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade800,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  trackingCategory,
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (progress >= 1.0)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.black,
                              size: 10,
                            ),
                          ),
                        ),
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          size: 18,
                          color: Colors.grey,
                        ),
                        onPressed: () =>
                            _showEditGoalDialog(context, provider, goal),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Progress bar
              Stack(
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress.clamp(0.0, 1.0), // Ensure double
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: progress >= 1.0
                              ? [AppColors.success, AppColors.success]
                              : [
                                  Color(goal.colorValue),
                                  Color(goal.colorValue).withValues(alpha: 0.7),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (progress >= 1.0
                                        ? AppColors.success
                                        : Color(goal.colorValue))
                                    .withValues(alpha: 0.4),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildGoalStat(
                    'Progress',
                    '$progressPercent%',
                    Color(goal.colorValue),
                  ),
                  _buildGoalStat(
                    'Daily',
                    '${goal.targetMinutes}m',
                    Colors.grey,
                  ),
                  _buildGoalStat('Streak', '$streak', AppColors.accent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _deleteGoalWithUndo(
    BuildContext context,
    TimeTrackerProvider provider,
    Goal goal,
  ) async {
    // Temporarily remove from UI but don't delete yet
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    bool shouldDelete = true;

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text('Goal "${goal.name}" deleted'),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.grey.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: AppColors.accent,
          onPressed: () {
            shouldDelete = false;
          },
        ),
      ),
    );

    // Wait for snackbar duration
    await Future.delayed(const Duration(seconds: 3, milliseconds: 100));

    if (shouldDelete) {
      provider.deleteGoal(goal.id);
    }

    return false; // Return false since we handle deletion ourselves
  }

  void _showAttendanceAnalysisDialog(
    BuildContext context,
    TimeTrackerProvider provider,
    Goal goal,
  ) {
    final color = Color(goal.colorValue);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Consumer<TimeTrackerProvider>(
        builder: (ctx, prov, _) {
          final stats = prov.getAttendanceStats(goal);
          return Container(
            height: MediaQuery.of(sheetContext).size.height * 0.85,
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 20),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade700,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                color.withValues(alpha: 0.15),
                                Colors.transparent,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: color.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  Icons.school,
                                  color: color,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      goal.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            'ATTENDANCE',
                                            style: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.6,
                                              ),
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Key Metrics
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricCard(
                                'ATTENDED',
                                '${stats['semester']}',
                                'Total',
                                color,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMetricCard(
                                'RATE',
                                stats['total'] == 0
                                    ? '0%'
                                    : '${((stats['semester'] as int) / (stats['total'] as int) * 100).toInt()}%',
                                'Attendance',
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMetricCard(
                                'MISSED',
                                '${(stats['total'] as int) - (stats['semester'] as int)}',
                                'Classes',
                                Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // GitHub-style Attendance Heatmap
                        const Text(
                          'ATTENDANCE HISTORY',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildAttendanceHeatmap(prov, goal, color),
                        const SizedBox(height: 32),

                        // Recent History
                        const Text(
                          'RECENT EVENTS',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildRecentAttendanceList(prov, goal),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentAttendanceList(TimeTrackerProvider provider, Goal goal) {
    final now = DateTime.now();
    // Generate instances for last 30 days (history) and next 7 days (upcoming)
    final startRange = now.subtract(const Duration(days: 30));

    List<ScheduledEvent> allInstances = [];

    // Iterate through each day in range to generate instances
    for (int i = 0; i <= 37; i++) {
      final date = startRange.add(Duration(days: i));
      final dayEvents = provider.getEventsForDate(date, includeExcluded: true);

      final matches = dayEvents.where((e) {
        // Logic to match goal
        if (goal.eventTitlePattern != null &&
            goal.eventTitlePattern!.isNotEmpty) {
          final normalizedTitle = e.title.trim().toLowerCase().replaceAll(
            RegExp(r'\s+'),
            ' ',
          );
          final normalizedPattern = goal.eventTitlePattern!
              .trim()
              .toLowerCase()
              .replaceAll(RegExp(r'\s+'), ' ');
          return normalizedTitle == normalizedPattern;
        }
        return e.linkedTaskId == goal.taskId;
      });
      allInstances.addAll(matches);
    }

    // Sort desc (newest first)
    allInstances.sort((a, b) => b.startTime.compareTo(a.startTime));

    if (allInstances.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(Icons.event_busy, color: Colors.grey, size: 48),
              SizedBox(height: 16),
              Text(
                "No events found in recent history",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: allInstances.take(15).map((e) {
        final dateKey = DateTime(
          e.startTime.year,
          e.startTime.month,
          e.startTime.day,
        );
        final isCancelled =
            e.excludedDates?.any(
              (d) =>
                  d.year == dateKey.year &&
                  d.month == dateKey.month &&
                  d.day == dateKey.day,
            ) ??
            false;

        final isDone = e.isCompleted;
        final isFuture = e.startTime.isAfter(now);

        Color statusColor;
        IconData statusIcon;
        String statusText;

        if (isCancelled) {
          statusColor = Colors.orange;
          statusIcon = Icons.block;
          statusText = 'CANCELLED';
        } else if (isDone) {
          statusColor = Colors.green;
          statusIcon = Icons.check_circle;
          statusText = 'ATTENDED';
        } else if (isFuture) {
          statusColor = Colors.blue;
          statusIcon = Icons.schedule;
          statusText = 'UPCOMING';
        } else {
          statusColor = Colors.red;
          statusIcon = Icons.cancel;
          statusText = 'MISSED';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: statusColor.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // Status Bar
                  Container(width: 6, color: statusColor),
                  const SizedBox(width: 12),
                  // Icon
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(statusIcon, color: statusColor, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Info
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              e.title,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                decoration: isCancelled
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: statusColor.withValues(alpha: 0.2),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${DateFormat('EEEE, MMM d').format(e.startTime)} at ${DateFormat('h:mm a').format(e.startTime)}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Actions
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!isFuture && !isCancelled)
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: isDone,
                            onChanged: (val) {
                              provider.toggleEventCompletion(e.id, e.startTime);
                              (context as Element).markNeedsBuild();
                            },
                            activeThumbColor: Colors.green,
                          ),
                        ),
                      Row(
                        children: [
                          if (!isDone)
                            IconButton(
                              icon: Icon(
                                isCancelled ? Icons.undo : Icons.close,
                                color: isCancelled
                                    ? Colors.blue
                                    : Colors.red.withValues(alpha: 0.5),
                                size: 18,
                              ),
                              tooltip: isCancelled
                                  ? 'Uncancel'
                                  : 'Cancel Class',
                              onPressed: () {
                                provider.toggleEventExclusion(
                                  e.id,
                                  e.startTime,
                                );
                                (context as Element).markNeedsBuild();
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// GitHub-style attendance heatmap showing the last 90 days
  /// Month-based attendance calendar showing attendance history
  Widget _buildAttendanceHeatmap(
    TimeTrackerProvider provider,
    Goal goal,
    Color accentColor,
  ) {
    // Height constrained for scrollable region (compact)
    return SizedBox(
      height: 340,
      child: PageView.builder(
        // Start in the middle to allow scrolling back and forth
        controller: PageController(initialPage: 50, viewportFraction: 0.92),
        itemCount: 100, // Range of months
        itemBuilder: (context, index) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          // Calculate month for this page (index 50 is current month)
          final monthOffset = index - 50;
          final currentMonth = DateTime(now.year, now.month + monthOffset, 1);
          final daysInMonth = DateTime(
            currentMonth.year,
            currentMonth.month + 1,
            0,
          ).day;
          final firstWeekday = currentMonth.weekday; // 1 = Monday

          // Generate attendance data for the month
          Map<int, Map<String, dynamic>> monthData = {};

          for (int day = 1; day <= daysInMonth; day++) {
            final date = DateTime(currentMonth.year, currentMonth.month, day);
            final events = provider.getEventsForDate(
              date,
              includeExcluded: true,
            );

            // Strict normalized matching
            final matchingEvents = events.where((e) {
              if (goal.eventTitlePattern != null &&
                  goal.eventTitlePattern!.isNotEmpty) {
                final normalizedTitle = e.title.trim().toLowerCase().replaceAll(
                  RegExp(r'\s+'),
                  ' ',
                );
                final normalizedPattern = goal.eventTitlePattern!
                    .trim()
                    .toLowerCase()
                    .replaceAll(RegExp(r'\s+'), ' ');
                return normalizedTitle == normalizedPattern;
              }
              return e.linkedTaskId == goal.taskId;
            }).toList();

            int attended = 0;
            int missed = 0;
            int cancelled = 0;
            int upcoming = 0;

            for (var e in matchingEvents) {
              final isCancelled =
                  e.excludedDates?.any(
                    (d) =>
                        d.year == date.year &&
                        d.month == date.month &&
                        d.day == date.day,
                  ) ??
                  false;

              if (isCancelled) {
                cancelled++;
              } else if (e.isCompleted) {
                attended++;
              } else if (date.isBefore(today) ||
                  (date.isAtSameMomentAs(today) && e.startTime.isBefore(now))) {
                missed++;
              } else {
                upcoming++;
              }
            }

            monthData[day] = {
              'attended': attended,
              'missed': missed,
              'cancelled': cancelled,
              'upcoming': upcoming,
              'total': matchingEvents.length,
            };
          }

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month header
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('MMMM yyyy').format(currentMonth),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Legend (Simplified)
                      Row(
                        children: [
                          _buildLegendDot(Colors.green, '✓'),
                          const SizedBox(width: 8),
                          _buildLegendDot(Colors.red, '✗'),
                          const SizedBox(width: 8),
                          _buildLegendDot(Colors.orange, '⊘'),
                        ],
                      ),
                    ],
                  ),
                ),

                // Day of week headers
                Row(
                  children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                      .map(
                        (d) => Expanded(
                          child: Center(
                            child: Text(
                              d,
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 8),

                // Calendar grid
                Expanded(
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 2,
                          crossAxisSpacing: 2,
                          childAspectRatio: 1.0,
                        ),
                    itemCount: 42, // Fixed grid size
                    itemBuilder: (context, index) {
                      final dayOffset = index - (firstWeekday - 1);
                      if (dayOffset < 1 || dayOffset > daysInMonth) {
                        return const SizedBox();
                      }

                      final dayNum = dayOffset;
                      final data = monthData[dayNum]!;
                      final attended = data['attended'] as int;
                      final missed = data['missed'] as int;
                      final cancelled = data['cancelled'] as int;
                      final upcoming = data['upcoming'] as int;
                      final total = data['total'] as int;

                      // Using 'currentMonth' for the isToday check
                      final isCurrentDay =
                          dayNum == today.day &&
                          currentMonth.year == today.year &&
                          currentMonth.month == today.month;

                      Color bgColor = Colors.grey.shade900;
                      if (total > 0) {
                        if (cancelled > 0 &&
                            attended == 0 &&
                            missed == 0 &&
                            upcoming == 0) {
                          bgColor = Colors.orange.withValues(alpha: 0.3);
                        } else if (attended > 0 && missed == 0) {
                          bgColor = Colors.green.withValues(alpha: 0.3);
                        } else if (missed > 0) {
                          bgColor = Colors.red.withValues(alpha: 0.3);
                        } else if (upcoming > 0) {
                          bgColor = Colors.blue.withValues(alpha: 0.2);
                        }
                      }

                      return GestureDetector(
                        onTap: () {
                          if (total > 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${DateFormat('MMM d').format(DateTime(currentMonth.year, currentMonth.month, dayNum))}: '
                                  '${attended > 0 ? "$attended attended, " : ""}'
                                  '${missed > 0 ? "$missed missed" : ""}'
                                  '${cancelled > 0 ? " (cancelled)" : ""}',
                                ),
                                backgroundColor: Colors.grey.shade800,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isCurrentDay
                                  ? accentColor
                                  : Colors.transparent,
                              width: isCurrentDay ? 2 : 0,
                            ),
                          ),
                          child: Center(
                            child: Stack(
                              children: [
                                Center(
                                  child: Text(
                                    '$dayNum',
                                    style: TextStyle(
                                      color: isCurrentDay
                                          ? accentColor
                                          : Colors.white70,
                                      fontSize: 10,
                                      fontWeight: isCurrentDay
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (total > 0 &&
                                    attended == 0 &&
                                    missed == 0 &&
                                    cancelled == 0)
                                  Positioned(
                                    bottom: 2,
                                    right: 2,
                                    child: Icon(
                                      Icons.circle,
                                      size: 4,
                                      color: Colors.blue,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLegendDot(Color color, String icon) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1),
      ),
      child: Center(
        child: Text(icon, style: TextStyle(fontSize: 10, color: color)),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, String sub, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            sub,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showGoalAnalysisDialog(
    BuildContext context,
    TimeTrackerProvider provider,
    Goal goal,
  ) {
    // 1. Gather Data
    final history = provider.history;
    final relevantEntries = history
        .where(
          (e) => goal.taskId == null || goal.taskId!.isEmpty
              ? true // If generic, maybe count everything? Or maybe nothing? Assuming filtered by something.
              // Actually, if generic, calculating specific analytics is hard. Let's filter by ONLY relevant task ID if present.
              : e.taskId == goal.taskId,
        )
        .toList();

    // Total Time
    final totalDuration = relevantEntries.fold(
      Duration.zero,
      (p, e) => p + e.duration,
    );

    // Day of Week Distribution (Mon=1 ... Sun=7)
    final Map<int, int> dayDist = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
    for (var e in relevantEntries) {
      dayDist[e.startTime.weekday] =
          (dayDist[e.startTime.weekday] ?? 0) + e.duration.inMinutes;
    }

    // Time of Day Distribution
    // Morning (5-12), Afternoon (12-17), Evening (17-22), Night (22-5)
    int morning = 0;
    int afternoon = 0;
    int evening = 0;
    int night = 0;

    for (var e in relevantEntries) {
      final h = e.startTime.hour;
      final m = e.duration.inMinutes;
      if (h >= 5 && h < 12) {
        morning += m;
      } else if (h >= 12 && h < 17)
        afternoon += m;
      else if (h >= 17 && h < 22)
        evening += m;
      else
        night += m;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey.shade900,
              Colors.grey.shade900.withValues(alpha: 0.98),
            ],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade700,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with goal info and progress ring
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(goal.colorValue).withValues(alpha: 0.15),
                            Color(goal.colorValue).withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Color(goal.colorValue).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Progress Ring
                          SizedBox(
                            width: 70,
                            height: 70,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: provider
                                      .getGoalProgress(goal)
                                      .clamp(0.0, 1.0),
                                  strokeWidth: 6,
                                  backgroundColor: Colors.grey.shade800,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(goal.colorValue),
                                  ),
                                ),
                                Text(
                                  '${(provider.getGoalProgress(goal) * 100).clamp(0, 100).round()}%',
                                  style: TextStyle(
                                    color: Color(goal.colorValue),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  goal.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  relevantEntries.isEmpty
                                      ? 'No data yet'
                                      : 'Total ${totalDuration.inHours}h ${totalDuration.inMinutes.remainder(60)}m tracked',
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(
                                      goal.colorValue,
                                    ).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${goal.targetMinutes}m daily target',
                                    style: TextStyle(
                                      color: Color(goal.colorValue),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // METRICS ROW
                    Row(
                      children: [
                        Expanded(
                          child: _buildAnalysisMetric(
                            'BEST STREAK',
                            '${provider.getGoalStreak(goal)} days',
                            Icons.local_fire_department,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildAnalysisMetric(
                            'AVG SESSION',
                            relevantEntries.isEmpty
                                ? '0m'
                                : '${(totalDuration.inMinutes / relevantEntries.length).round()}m',
                            Icons.timer,
                            Colors.blue,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // CONSISTENCY HEATMAP
                    _buildSectionLabel('CONSISTENCY HISTORY'),
                    const SizedBox(height: 12),
                    _buildConsistencyHeatmap(dayDist, goal, relevantEntries),

                    const SizedBox(height: 28),

                    // TIME OF DAY
                    _buildSectionLabel('MOST ACTIVE TIMES'),
                    const SizedBox(height: 12),
                    _buildTimeRow(
                      'Morning (5AM - 12PM)',
                      morning,
                      totalDuration.inMinutes,
                      Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    _buildTimeRow(
                      'Afternoon (12PM - 5PM)',
                      afternoon,
                      totalDuration.inMinutes,
                      Colors.yellow,
                    ),
                    const SizedBox(height: 12),
                    _buildTimeRow(
                      'Evening (5PM - 10PM)',
                      evening,
                      totalDuration.inMinutes,
                      Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _buildTimeRow(
                      'Night (10PM - 5AM)',
                      night,
                      totalDuration.inMinutes,
                      Colors.indigo,
                    ),

                    const SizedBox(height: 28),

                    // DETAILED LOG
                    _buildSectionLabel('DETAILED LOG'),
                    const SizedBox(height: 12),
                    if (relevantEntries.isEmpty)
                      const Text(
                        'No activity logged yet.',
                        style: TextStyle(color: Colors.grey),
                      )
                    else
                      ...relevantEntries.reversed.map((entry) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade800.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.05),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Color(goal.colorValue),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormat(
                                        'EEE, MMM d, yyyy',
                                      ).format(entry.startTime),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${DateFormat('h:mm a').format(entry.startTime)} - ${DateFormat('h:mm a').format(entry.endTime ?? DateTime.now())}',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (entry.note != null && entry.note!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: Icon(
                                    Icons.sticky_note_2,
                                    size: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _formatDuration(entry.duration),
                                  style: TextStyle(
                                    color: Colors.grey.shade300,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.grey.shade500,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildAnalysisMetric(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 120, // Enforce consistent height
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade800.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 9)),
      ],
    );
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    return '${d.inMinutes}m';
  }

  Widget _buildConsistencyHeatmap(
    Map<int, int> dayDist,
    Goal goal,
    List<TimeEntry> entries,
  ) {
    // 1. Prepare Daily Data
    final dailyMinutes = <String, int>{};
    for (var e in entries) {
      final key = DateFormat('yyyy-MM-dd').format(e.startTime);
      dailyMinutes[key] = (dailyMinutes[key] ?? 0) + e.duration.inMinutes;
    }

    final now = DateTime.now();
    return SizedBox(
      height: 190, // Compact height for small cards
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        reverse: true, // Start from current month (rightmost)
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: 13, // Show last 12 months + current
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          // Calculate month: Index 0 = Current, Index 1 = Previous...
          final currentMonth = DateTime(now.year, now.month - index, 1);
          final daysInMonth = DateTime(
            currentMonth.year,
            currentMonth.month + 1,
            0,
          ).day;
          final firstWeekday = currentMonth.weekday; // 1 = Monday

          return Container(
            width: 160, // Fixed small width (~2.3 cards per screen)
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month header (Compact)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    DateFormat('MMMM yyyy').format(currentMonth),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12, // Small title
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Day of week headers (Tiny)
                Row(
                  children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                      .map(
                        (d) => Expanded(
                          child: Center(
                            child: Text(
                              d,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 8, // Tiny headers
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 6),

                // Calendar grid
                Expanded(
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 3, // Tighter spacing
                          crossAxisSpacing: 3,
                          childAspectRatio: 1.0,
                        ),
                    itemCount: 42,
                    itemBuilder: (context, gridIndex) {
                      final dayOffset = gridIndex - (firstWeekday - 1);
                      if (dayOffset < 1 || dayOffset > daysInMonth) {
                        return const SizedBox();
                      }

                      final dayNum = dayOffset;
                      final date = DateTime(
                        currentMonth.year,
                        currentMonth.month,
                        dayNum,
                      );
                      final dateKey = DateFormat('yyyy-MM-dd').format(date);
                      final minutes = dailyMinutes[dateKey] ?? 0;
                      final target = goal.targetMinutes;
                      final isFuture = date.isAfter(now);

                      final isCurrentDay =
                          dayNum == now.day &&
                          currentMonth.year == now.year &&
                          currentMonth.month == now.month;

                      Color bgColor = Colors.grey.shade900;
                      Color borderColor = Colors.transparent;

                      if (isFuture) {
                        bgColor = Colors.transparent;
                        borderColor = Colors.grey.shade800;
                      } else if (minutes > 0) {
                        final ratio = target > 0 ? minutes / target : 1.0;
                        if (ratio >= 1.0) {
                          bgColor = Color(goal.colorValue);
                        } else if (ratio >= 0.5) {
                          bgColor = Color(
                            goal.colorValue,
                          ).withValues(alpha: 0.6);
                        } else {
                          bgColor = Color(
                            goal.colorValue,
                          ).withValues(alpha: 0.3);
                        }
                      }

                      if (isCurrentDay) {
                        borderColor = Colors.white;
                      }

                      return Tooltip(
                        message: '$dayNum: ${minutes}m',
                        child: Container(
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(
                              4,
                            ), // Smaller radius
                            border: Border.all(
                              color: borderColor,
                              width: isFuture ? 0.5 : (isCurrentDay ? 1.5 : 0),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '$dayNum',
                              style: TextStyle(
                                color: minutes > 0 || isCurrentDay
                                    ? Colors.white
                                    : Colors.grey.shade700,
                                fontSize: 8, // Tiny numbers
                                fontWeight: (minutes > 0 || isCurrentDay)
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeRow(String label, int value, int total, Color color) {
    final percent = total > 0 ? (value / total) : 0.0;

    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(
            '${(percent * 100).round()}%',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: percent.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  IconData _getGoalIcon(String contributionType) {
    switch (contributionType) {
      case 'event':
        return Icons.event_available;
      case 'time':
      default:
        return Icons.timer_outlined;
    }
  }

  void _showAddGoalDialog(
    BuildContext context,
    TimeTrackerProvider provider, {
    String? type,
  }) {
    _showGoalDialog(context, provider, null, type: type);
  }

  void _showEditGoalDialog(
    BuildContext context,
    TimeTrackerProvider provider,
    Goal goal,
  ) {
    _showGoalDialog(context, provider, goal);
  }

  void _showGoalDialog(
    BuildContext context,
    TimeTrackerProvider provider,
    Goal? goal, {
    String? type,
  }) {
    final isEditing = goal != null;
    final nameController = TextEditingController(text: goal?.name ?? '');
    int targetMinutes = goal?.targetMinutes ?? 60;
    String selectedTaskId = goal?.taskId ?? '';
    Color selectedColor = goal != null
        ? Color(goal.colorValue)
        : AppColors.palette[0];

    // Default to 'time' unless 'event' is passed or existing goal is 'event'
    String contributionType = goal?.contributionType ?? type ?? 'time';
    int targetCount = goal?.targetCount ?? 1;
    String eventTitlePattern = goal?.eventTitlePattern ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Consumer<TimeTrackerProvider>(
        builder: (context, provider, _) {
          final tasks = provider.tasks.where((t) => t.id != 'unknown').toList();

          return StatefulBuilder(
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
                          isEditing
                              ? (contributionType == 'event'
                                    ? 'Edit Attendance Track'
                                    : 'Edit Goal')
                              : (contributionType == 'event'
                                    ? 'Create Attendance Track'
                                    : 'New Goal'),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Goal type info
                    // Goal type info
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            contributionType == 'event'
                                ? Icons.event_available
                                : Icons.timer_outlined,
                            size: 16,
                            color: contributionType == 'event'
                                ? Colors.blue
                                : AppColors.accent,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              contributionType == 'event'
                                  ? 'Track attendance by counting calendar events'
                                  : 'Track daily time spent on activities',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'e.g. "Study 2 hours daily"',
                        hintStyle: TextStyle(color: Colors.grey.shade600),
                        filled: true,
                        fillColor: Colors.grey.shade800,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Task selection
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          contributionType == 'event'
                              ? 'Track events in'
                              : 'Track time on',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                        GestureDetector(
                          onTap: () =>
                              _showQuickCreateTaskDialog(context, provider),
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
                          'Any task',
                          '',
                          selectedTaskId,
                          Colors.grey,
                          () => setDialogState(() => selectedTaskId = ''),
                        ),
                        ...tasks.map(
                          (task) => _buildTaskChip(
                            task.name,
                            task.id,
                            selectedTaskId,
                            task.color,
                            () =>
                                setDialogState(() => selectedTaskId = task.id),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Target
                    if (contributionType == 'time') ...[
                      Text(
                        'Daily target: $targetMinutes minutes',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: targetMinutes.toDouble(),
                        min: 15,
                        max: 480,
                        divisions: 31,
                        activeColor: AppColors.accent,
                        inactiveColor: Colors.grey.shade800,
                        onChanged: (value) =>
                            setDialogState(() => targetMinutes = value.round()),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '15m',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            '8h',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (contributionType == 'event') ...[
                      const SizedBox(height: 8),
                      Text(
                        'Select Calendar Event to Track',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Dropdown for Recurring Events
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value:
                                eventTitlePattern.isNotEmpty &&
                                    provider.events.any(
                                      (e) => e.title == eventTitlePattern,
                                    )
                                ? eventTitlePattern
                                : null,
                            hint: Text(
                              provider.events
                                      .where((e) => e.recurrenceType != 'none')
                                      .isEmpty
                                  ? 'No recurring events found. Create one below.'
                                  : 'Choose a recurring Class/Event',
                              style: TextStyle(color: Colors.grey.shade400),
                            ),
                            dropdownColor: Colors.grey.shade800,
                            isExpanded: true,
                            items: [
                              ...provider.events
                                  .where((e) => e.recurrenceType != 'none')
                                  .map((e) => e.title)
                                  .toSet() // Deduplicate titles
                                  .map(
                                    (title) => DropdownMenuItem(
                                      value: title,
                                      child: Text(
                                        title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() => eventTitlePattern = val);
                              }
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),
                      // Manual override / Fallback
                      ExpansionTile(
                        title: const Text(
                          'Or enter manually',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        collapsedIconColor: Colors.grey,
                        tilePadding: EdgeInsets.zero,
                        children: [
                          TextFormField(
                            initialValue: eventTitlePattern,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                            ),
                            onChanged: (val) => eventTitlePattern = val,
                            decoration: InputDecoration(
                              hintText: 'e.g. "Physics 101"',
                              hintStyle: TextStyle(color: Colors.grey.shade600),
                              filled: true,
                              fillColor: Colors.grey.shade800,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Colors.blue,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Attendance is tracked automatically when calendar events match the Name defined above.',
                                style: TextStyle(
                                  color: Colors.blue.shade200,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Option to create calendar event if creating new
                      if (!isEditing)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: GestureDetector(
                            onTap: () async {
                              // Open dialog ON TOP of this one
                              final newEventName =
                                  await _showQuickCreateEventDialog(
                                    context,
                                    provider,
                                    linkedTaskId: selectedTaskId.isNotEmpty
                                        ? selectedTaskId
                                        : null,
                                  );

                              if (newEventName != null && context.mounted) {
                                // Event created! Auto-select it and refresh UI
                                setDialogState(() {
                                  eventTitlePattern = newEventName;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.accent.withValues(alpha: 0.2),
                                    AppColors.accent.withValues(alpha: 0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.accent.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 18,
                                    color: AppColors.accent,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    "Create Calendar Schedule Now",
                                    style: TextStyle(
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],

                    const SizedBox(height: 16),

                    // Color
                    Text(
                      'Color',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: AppColors.palette.map((color) {
                        final isSelected = selectedColor == color;
                        return GestureDetector(
                          onTap: () =>
                              setDialogState(() => selectedColor = color),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(color: Colors.white, width: 2)
                                  : null,
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: color.withValues(alpha: 0.5),
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (nameController.text.isNotEmpty) {
                            if (isEditing) {
                              provider.updateGoal(
                                goal.id,
                                name: nameController.text,
                                taskId: selectedTaskId.isEmpty
                                    ? null
                                    : selectedTaskId,
                                targetMinutes: targetMinutes,
                                colorValue: selectedColor.value,
                                contributionType: contributionType,
                                targetCount: targetCount,
                                eventTitlePattern: eventTitlePattern.isEmpty
                                    ? null
                                    : eventTitlePattern,
                              );
                            } else {
                              provider.addGoal(
                                name: nameController.text,
                                taskId: selectedTaskId.isEmpty
                                    ? null
                                    : selectedTaskId,
                                targetMinutes: targetMinutes,
                                colorValue: selectedColor.value,
                                contributionType: contributionType,
                                targetCount: targetCount,
                                eventTitlePattern: eventTitlePattern.isEmpty
                                    ? null
                                    : eventTitlePattern,
                              );
                            }
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          isEditing ? 'SAVE CHANGES' : 'CREATE GOAL',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (isEditing)
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            // Better: confirm on top?
                            // Actually, let's close Edit Dialog then show Confirm? Or Show Confirm on top.
                            _confirmDeleteGoal(context, provider, goal);
                          },
                          child: Text(
                            'Delete Goal',
                            style: TextStyle(color: Colors.red.shade400),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDeleteGoal(
    BuildContext context,
    TimeTrackerProvider provider,
    Goal goal,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text(
          'Delete Goal?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will stop tracking progress for this goal. Historical data on tasks will remain.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              provider.deleteGoal(goal.id);
              Navigator.pop(context); // Close Confirm
              // If Edit Dialog was closed already, we are done.
              // Logic above: I didn't close Edit Dialog?
              // If I didn't close Edit Dialog, I need to close it too.
              // Current logic: Edit Dialog is underneath.
              // I should close Edit Dialog in the callback above OR here.
              // I'll close it here if I can?
              // Actually, closing Edit Dialog *before* showing Confirm is cleaner visually.
            },
            child: Text('DELETE', style: TextStyle(color: Colors.red.shade400)),
          ),
        ],
      ),
    );
  }

  void _showQuickCreateTaskDialog(
    BuildContext context,
    TimeTrackerProvider provider,
  ) {
    final nameController = TextEditingController();
    Color selectedColor = AppColors.palette[0];
    String selectedCategory = 'LEARNING';
    final categories = provider.getCategories();
    if (categories.isNotEmpty) selectedCategory = categories.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
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
                const Text(
                  'Quick Create Task',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Task Name (e.g. "Piano Practice")',
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    filled: true,
                    fillColor: Colors.grey.shade800,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Category',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.map((cat) {
                      final isSelected = selectedCategory == cat;
                      return GestureDetector(
                        onTap: () => setState(() => selectedCategory = cat),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.accent.withValues(alpha: 0.2)
                                : Colors.grey.shade800,
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected
                                ? Border.all(color: AppColors.accent)
                                : null,
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.accent
                                  : Colors.grey.shade400,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Color',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: AppColors.palette.map((color) {
                    final isSelected = selectedColor == color;
                    return GestureDetector(
                      onTap: () => setState(() => selectedColor = color),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 2)
                              : null,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                  ),
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (nameController.text.isNotEmpty) {
                        final baseType = provider.getCategoryBaseType(
                          selectedCategory,
                        );
                        provider.addTask(
                          name: nameController.text,
                          category: selectedCategory,
                          baseType: baseType,
                          colorValue: selectedColor.value,
                        );
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'CREATE TASK',
                      style: TextStyle(fontWeight: FontWeight.bold),
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
    String label,
    String id,
    String selectedId,
    Color color,
    VoidCallback onTap,
  ) {
    final isSelected = id == selectedId;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.2)
              : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? Border.all(color: color) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey.shade400,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceSection(
    TimeTrackerProvider provider,
    List<Goal> goals,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('ATTENDANCE', Icons.class_outlined, goals.length),
          const SizedBox(height: 12),
          if (goals.isEmpty)
            _buildEmptyCard(
              'No attendance tracks',
              'Track class attendance automatically',
            )
          else
            ...goals.map((g) => _buildAttendanceCard(provider, g)),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(TimeTrackerProvider provider, Goal goal) {
    final stats = provider.getAttendanceStats(goal);
    final color = Color(goal.colorValue);

    return Dismissible(
      key: Key(goal.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      confirmDismiss: (direction) async {
        return await _deleteGoalWithUndo(context, provider, goal);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showAttendanceAnalysisDialog(context, provider, goal),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon Box
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(Icons.school, color: color, size: 24),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Matches: "${goal.eventTitlePattern}"',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Count Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade800),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${stats['semester']}/${stats['total']}',
                          style: TextStyle(
                            color: color,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'ATTENDED',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 8,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Rate Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade800),
                    ),
                    child: Column(
                      children: [
                        Text(
                          stats['total'] == 0
                              ? '0%'
                              : '${((stats['semester'] as int) / (stats['total'] as int) * 100).toInt()}%',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'RATE',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 8,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Edit Button
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
                    onPressed: () =>
                        _showEditGoalDialog(context, provider, goal),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Edit',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<String?> _showQuickCreateEventDialog(
    BuildContext context,
    TimeTrackerProvider provider, {
    String? linkedTaskId,
  }) async {
    final titleController = TextEditingController();
    // Default: Today!
    List<int> selectedDays = [DateTime.now().weekday];
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 10, minute: 0);

    return await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            backgroundColor: Colors.grey.shade900,
            title: const Text(
              'Create Recurring Event',
              style: TextStyle(color: Colors.white),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Event Name (e.g. Physics Class)',
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Days', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: List.generate(7, (index) {
                      final day = index + 1;
                      final isSelected = selectedDays.contains(day);
                      final labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              if (selectedDays.length > 1) {
                                selectedDays.remove(day);
                              }
                            } else {
                              selectedDays.add(day);
                            }
                          });
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.accent
                                : Colors.grey.shade800,
                            shape: BoxShape.circle,
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
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final t = await showTimePicker(
                              context: context,
                              initialTime: startTime,
                            );
                            if (t != null) setState(() => startTime = t);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Start: ${startTime.format(context)}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final t = await showTimePicker(
                              context: context,
                              initialTime: endTime,
                            );
                            if (t != null) setState(() => endTime = t);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'End: ${endTime.format(context)}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isNotEmpty) {
                    final now = DateTime.now();
                    final start = DateTime(
                      now.year,
                      now.month,
                      now.day,
                      startTime.hour,
                      startTime.minute,
                    );
                    final end = DateTime(
                      now.year,
                      now.month,
                      now.day,
                      endTime.hour,
                      endTime.minute,
                    );

                    await provider.addEvent(
                      title: titleController.text,
                      startTime: start,
                      endTime: end,
                      recurrenceType: 'weekly',
                      recurrenceDays: List.from(selectedDays),
                      colorValue: AppColors.palette[0].value, // Default color
                      linkedTaskId: linkedTaskId,
                      // Ends in 3 months by default
                      recurrenceEndTime: now.add(const Duration(days: 90)),
                    );
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext, titleController.text);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Create Event'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddMenu(BuildContext context, TimeTrackerProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create New',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.timer_outlined,
                  color: AppColors.accent,
                ),
              ),
              title: const Text(
                'New Goal',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                'Track daily time habits',
                style: TextStyle(color: Colors.grey.shade400),
              ),
              onTap: () {
                Navigator.pop(context);
                _showAddGoalDialog(context, provider, type: 'time');
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.school_outlined, color: Colors.blue),
              ),
              title: const Text(
                'New Attendance Tracker',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                'Track class/event counts',
                style: TextStyle(color: Colors.grey.shade400),
              ),
              onTap: () {
                Navigator.pop(context);
                _showAddGoalDialog(context, provider, type: 'event');
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.flag_outlined, color: Colors.orange),
              ),
              title: const Text(
                'New Deadline',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                'Tasks with due dates',
                style: TextStyle(color: Colors.grey.shade400),
              ),
              onTap: () {
                Navigator.pop(context);
                _showAddDeadlineDialog(context, provider);
              },
            ),
          ],
        ),
      ),
    );
  }
}
