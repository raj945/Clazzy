import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/time_tracking_provider.dart';
import '../models/time_entry.dart';
import '../constants/colors.dart';

/// Monthly Analytics Screen - Pure Visual Data Reporting
/// NO textual interpretations, NO AI commentary
/// Only charts, grids, and factual numbers
class MonthlyAnalyticsScreen extends StatefulWidget {
  const MonthlyAnalyticsScreen({super.key});

  @override
  State<MonthlyAnalyticsScreen> createState() => _MonthlyAnalyticsScreenState();
}

class _MonthlyAnalyticsScreenState extends State<MonthlyAnalyticsScreen> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + delta,
        1,
      );
    });
  }

  // Get all entries for the selected month
  List<TimeEntry> _getMonthEntries(TimeTrackerProvider provider) {
    final startOfMonth = _selectedMonth;
    final endOfMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
      23,
      59,
      59,
    );

    return provider.history.where((e) {
      return e.startTime.isAfter(
            startOfMonth.subtract(const Duration(days: 1)),
          ) &&
          e.startTime.isBefore(endOfMonth.add(const Duration(days: 1)));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TimeTrackerProvider>(context);
    final monthEntries = _getMonthEntries(provider);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month Selector
          _buildMonthSelector(),
          const SizedBox(height: 24),

          // 1. Monthly Time Allocation (Donut Chart)
          _buildSectionLabel('1. MONTHLY TIME ALLOCATION'),
          const SizedBox(height: 12),
          _buildTimeAllocationChart(monthEntries, provider),
          const SizedBox(height: 32),

          // 2. Category-wise Breakdown (Bar Chart)
          _buildSectionLabel('2. CATEGORY BREAKDOWN'),
          const SizedBox(height: 12),
          _buildCategoryBreakdown(monthEntries, provider),
          const SizedBox(height: 32),

          // 3. Goals vs Actual
          _buildSectionLabel('3. GOALS VS ACTUAL'),
          const SizedBox(height: 12),
          _buildGoalsVsActual(monthEntries, provider),
          const SizedBox(height: 32),

          // 4. Calendar Intent vs Reality
          _buildSectionLabel('4. CALENDAR: INTENT VS REALITY'),
          const SizedBox(height: 12),
          _buildCalendarHeatmap(monthEntries, provider),
          const SizedBox(height: 32),

          // 5. Consistency Heatmap
          _buildSectionLabel('5. CONSISTENCY'),
          const SizedBox(height: 12),
          _buildConsistencyHeatmap(monthEntries, provider),
          const SizedBox(height: 32),

          // 6. Daily Trend Lines
          _buildSectionLabel('6. DAILY TRENDS'),
          const SizedBox(height: 12),
          _buildDailyTrends(monthEntries, provider),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => _changeMonth(-1),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.chevron_left,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          Text(
            DateFormat('MMMM yyyy').format(_selectedMonth),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          GestureDetector(
            onTap: () => _changeMonth(1),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.chevron_right,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.grey.shade500,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }

  // ============================================
  // 1. MONTHLY TIME ALLOCATION - Donut Chart
  // ============================================
  Widget _buildTimeAllocationChart(
    List<TimeEntry> entries,
    TimeTrackerProvider provider,
  ) {
    if (entries.isEmpty) {
      return _buildEmptyState('No data for this month');
    }

    // Aggregate by base type
    final Map<String, int> distribution = {
      'Deep Work': 0,
      'Personal': 0,
      'Wasted': 0,
      'Sleep': 0,
      'Unassigned': 0,
    };

    for (var e in entries) {
      final task = provider.getTaskById(e.taskId);
      final duration = e.duration.inMinutes;

      if (task == null) {
        distribution['Unassigned'] = distribution['Unassigned']! + duration;
        continue;
      }

      final type = task.baseType.toUpperCase();
      if (type == 'DEEP WORK' || type == 'FOCUS') {
        distribution['Deep Work'] = distribution['Deep Work']! + duration;
      } else if (type == 'WASTED' || type == 'LEISURE') {
        distribution['Wasted'] = distribution['Wasted']! + duration;
      } else if (type == 'PERSONAL' || type == 'HEALTH') {
        distribution['Personal'] = distribution['Personal']! + duration;
      } else if (type == 'SLEEP') {
        distribution['Sleep'] = distribution['Sleep']! + duration;
      } else {
        distribution['Unassigned'] = distribution['Unassigned']! + duration;
      }
    }

    final totalMinutes = distribution.values.reduce((a, b) => a + b);
    if (totalMinutes == 0) {
      return _buildEmptyState('No tracked time this month');
    }

    final List<PieChartSectionData> sections = [];
    final colors = {
      'Deep Work': AppColors.accent,
      'Personal': Colors.blue,
      'Wasted': Colors.purple,
      'Sleep': Colors.teal,
      'Unassigned': Colors.grey,
    };

    distribution.forEach((key, value) {
      if (value > 0) {
        sections.add(
          PieChartSectionData(
            value: value.toDouble(),
            color: colors[key] ?? Colors.grey,
            radius: 50,
            title: '',
          ),
        );
      }
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 60,
                    sectionsSpace: 2,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatHoursMinutes(totalMinutes),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Total',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Legend with absolute time
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: distribution.entries.where((e) => e.value > 0).map((e) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colors[e.key],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${e.key}: ${_formatHoursMinutes(e.value)}',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ============================================
  // 2. CATEGORY BREAKDOWN - Horizontal Bars
  // ============================================
  Widget _buildCategoryBreakdown(
    List<TimeEntry> entries,
    TimeTrackerProvider provider,
  ) {
    if (entries.isEmpty) {
      return _buildEmptyState('No data for this month');
    }

    // Group by task
    final Map<String, _TaskStats> taskStats = {};

    for (var e in entries) {
      final task = provider.getTaskById(e.taskId);
      final taskName = task?.name ?? 'Unknown';
      final dayKey = DateFormat('yyyy-MM-dd').format(e.startTime);

      taskStats.putIfAbsent(
        taskName,
        () => _TaskStats(name: taskName, color: task?.color ?? Colors.grey),
      );
      taskStats[taskName]!.totalMinutes += e.duration.inMinutes;
      taskStats[taskName]!.activeDays.add(dayKey);
    }

    // Sort by total time
    final sortedTasks = taskStats.values.toList()
      ..sort((a, b) => b.totalMinutes.compareTo(a.totalMinutes));

    final maxMinutes = sortedTasks.isNotEmpty
        ? sortedTasks.first.totalMinutes
        : 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: sortedTasks.take(10).map((stat) {
          final barWidth = (stat.totalMinutes / maxMinutes).clamp(0.05, 1.0);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        stat.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          _formatHoursMinutes(stat.totalMinutes),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
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
                            '${stat.activeDays.length}d',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  height: 8,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: barWidth,
                    child: Container(
                      decoration: BoxDecoration(
                        color: stat.color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ============================================
  // 3. GOALS VS ACTUAL - Progress Bars
  // ============================================
  Widget _buildGoalsVsActual(
    List<TimeEntry> entries,
    TimeTrackerProvider provider,
  ) {
    final goals = provider.goals;
    if (goals.isEmpty) {
      return _buildEmptyState('No goals set');
    }

    // Calculate days in selected month
    final daysInMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    ).day;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: goals.map((goal) {
          // Monthly target = daily target * days in month
          final targetMinutes = goal.targetMinutes * daysInMonth;

          // Calculate actual time for this goal
          int actualMinutes = 0;
          for (var e in entries) {
            if (goal.taskId == null || e.taskId == goal.taskId) {
              if (goal.taskId != null) {
                actualMinutes += e.duration.inMinutes;
              }
            }
          }

          // If no specific task, count all tracked time
          if (goal.taskId == null) {
            actualMinutes = entries.fold(
              0,
              (sum, e) => sum + e.duration.inMinutes,
            );
          }

          final progress = targetMinutes > 0
              ? (actualMinutes / targetMinutes).clamp(0.0, 1.5)
              : 0.0;
          final isOverTarget = actualMinutes > targetMinutes;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        goal.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${_formatHoursMinutes(actualMinutes)} / ${_formatHoursMinutes(targetMinutes)}',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Stack(
                  children: [
                    // Background
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    // Target marker
                    Positioned.fill(
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color(goal.colorValue),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                    // Over-target indicator
                    if (isOverTarget)
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 4,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ============================================
  // 4. CALENDAR HEATMAP - Intent vs Reality
  // ============================================
  Widget _buildCalendarHeatmap(
    List<TimeEntry> entries,
    TimeTrackerProvider provider,
  ) {
    final daysInMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    ).day;
    final firstDayWeekday = DateTime(
      _selectedMonth.year,
      _selectedMonth.month,
      1,
    ).weekday;

    // Aggregate daily data
    final Map<int, int> dailyActual = {};
    final Map<int, int> dailyPlanned = {};

    for (var e in entries) {
      final day = e.startTime.day;
      dailyActual[day] = (dailyActual[day] ?? 0) + e.duration.inMinutes;
    }

    // Get planned events
    for (var event in provider.events) {
      if (event.startTime.year == _selectedMonth.year &&
          event.startTime.month == _selectedMonth.month) {
        final day = event.startTime.day;
        final duration = event.endTime.difference(event.startTime).inMinutes;
        dailyPlanned[day] = (dailyPlanned[day] ?? 0) + duration;
      }
    }

    final maxMinutes = dailyActual.values.isEmpty
        ? 1
        : dailyActual.values.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Weekday headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .map(
                  (d) => SizedBox(
                    width: 32,
                    child: Text(
                      d,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 10,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          // Calendar grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: ((daysInMonth + firstDayWeekday - 1) / 7).ceil() * 7,
            itemBuilder: (context, index) {
              final dayNumber = index - firstDayWeekday + 2;

              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox();
              }

              final actual = dailyActual[dayNumber] ?? 0;
              final planned = dailyPlanned[dayNumber] ?? 0;
              final intensity = actual > 0
                  ? (actual / maxMinutes).clamp(0.2, 1.0)
                  : 0.0;
              final hasPlanned = planned > 0;

              return Tooltip(
                message:
                    '${DateFormat('MMM d').format(DateTime(_selectedMonth.year, _selectedMonth.month, dayNumber))}\nActual: ${_formatHoursMinutes(actual)}\nPlanned: ${_formatHoursMinutes(planned)}',
                child: Container(
                  decoration: BoxDecoration(
                    color: actual > 0
                        ? AppColors.accent.withValues(alpha: intensity)
                        : Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(4),
                    border: hasPlanned
                        ? Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          )
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$dayNumber',
                    style: TextStyle(
                      color: actual > 0 ? Colors.black : Colors.grey.shade500,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 12, height: 12, color: Colors.grey.shade800),
              const SizedBox(width: 4),
              Text(
                'No data',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 9),
              ),
              const SizedBox(width: 12),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.5),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Planned + Actual',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================
  // 5. CONSISTENCY HEATMAP - GitHub Style
  // ============================================
  Widget _buildConsistencyHeatmap(
    List<TimeEntry> entries,
    TimeTrackerProvider provider,
  ) {
    final daysInMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    ).day;

    // Group by day
    final Map<int, int> dailyMinutes = {};
    for (var e in entries) {
      final day = e.startTime.day;
      dailyMinutes[day] = (dailyMinutes[day] ?? 0) + e.duration.inMinutes;
    }

    final maxMinutes = dailyMinutes.values.isEmpty
        ? 1
        : dailyMinutes.values.reduce((a, b) => a > b ? a : b);
    final avgMinutes = dailyMinutes.values.isEmpty
        ? 0
        : dailyMinutes.values.reduce((a, b) => a + b) ~/ dailyMinutes.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniStat('Active Days', '${dailyMinutes.length}'),
              _buildMiniStat('Avg/Day', _formatHoursMinutes(avgMinutes)),
              _buildMiniStat('Peak', _formatHoursMinutes(maxMinutes)),
            ],
          ),
          const SizedBox(height: 16),
          // Heatmap row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: List.generate(daysInMonth, (i) {
                final day = i + 1;
                final minutes = dailyMinutes[day] ?? 0;
                final intensity = minutes > 0
                    ? (minutes / maxMinutes).clamp(0.15, 1.0)
                    : 0.0;

                return Tooltip(
                  message: 'Day $day: ${_formatHoursMinutes(minutes)}',
                  child: Container(
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.only(right: 2),
                    decoration: BoxDecoration(
                      color: minutes > 0
                          ? AppColors.accent.withValues(alpha: intensity)
                          : Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          // Scale legend
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Less',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 9),
              ),
              const SizedBox(width: 4),
              ...List.generate(
                5,
                (i) => Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(right: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15 + (i * 0.2)),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'More',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
        ),
      ],
    );
  }

  // ============================================
  // 6. DAILY TRENDS - Line Charts
  // ============================================
  Widget _buildDailyTrends(
    List<TimeEntry> entries,
    TimeTrackerProvider provider,
  ) {
    final daysInMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    ).day;

    // Aggregate daily deep work and unassigned
    final List<FlSpot> deepWorkSpots = [];
    final List<FlSpot> unassignedSpots = [];

    for (int day = 1; day <= daysInMonth; day++) {
      int deepWork = 0;
      int unassigned = 0;

      for (var e in entries) {
        if (e.startTime.day == day) {
          final task = provider.getTaskById(e.taskId);
          final duration = e.duration.inMinutes;

          if (task == null) {
            unassigned += duration;
          } else {
            final type = task.baseType.toUpperCase();
            if (type == 'DEEP WORK' || type == 'FOCUS') {
              deepWork += duration;
            } else if (type == 'UNKNOWN') {
              unassigned += duration;
            }
          }
        }
      }

      deepWorkSpots.add(FlSpot(day.toDouble(), deepWork.toDouble()));
      unassignedSpots.add(FlSpot(day.toDouble(), unassigned.toDouble()));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Deep Work Trend
          Text(
            'Deep Work (minutes/day)',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: deepWorkSpots,
                    isCurved: false,
                    color: AppColors.accent,
                    barWidth: 2,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.accent.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Unassigned Trend
          Text(
            'Unassigned (minutes/day)',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: unassignedSpots,
                    isCurved: false,
                    color: Colors.grey,
                    barWidth: 2,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.grey.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // HELPERS
  // ============================================
  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        ),
      ),
    );
  }

  String _formatHoursMinutes(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) {
      return '${hours}h';
    }
    return '${hours}h ${mins}m';
  }
}

// Helper class for task statistics
class _TaskStats {
  final String name;
  final Color color;
  int totalMinutes = 0;
  Set<String> activeDays = {};

  _TaskStats({required this.name, required this.color});
}
