import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/time_tracking_provider.dart';
import '../models/time_entry.dart';
import '../constants/colors.dart';

class WeeklyAnalyticsScreen extends StatefulWidget {
  const WeeklyAnalyticsScreen({super.key});

  @override
  State<WeeklyAnalyticsScreen> createState() => _WeeklyAnalyticsScreenState();
}

class _WeeklyAnalyticsScreenState extends State<WeeklyAnalyticsScreen> {
  late DateTime _selectedDate;
  int _startDay = DateTime.monday; // Default: Monday (1)

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  void _changeWeek(int weeks) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: weeks * 7));
    });
  }

  DateTime _getStartOfWeek(DateTime date) {
    // Determine the start date based on _startDay
    // standard weekday: Mon=1 ... Sun=7.
    // Logic: subtract days until we hit _startDay
    int diff = (date.weekday - _startDay + 7) % 7;
    return date
        .subtract(Duration(days: diff))
        .copyWith(
          hour: 0,
          minute: 0,
          second: 0,
          millisecond: 0,
          microsecond: 0,
        );
  }

  List<TimeEntry> _getWeekEntries(TimeTrackerProvider provider) {
    final startOfWeek = _getStartOfWeek(_selectedDate);
    final endOfWeek = startOfWeek
        .add(const Duration(days: 7))
        .subtract(const Duration(seconds: 1));

    return provider.history.where((e) {
      return e.startTime.isAfter(
            startOfWeek.subtract(const Duration(seconds: 1)),
          ) &&
          e.startTime.isBefore(endOfWeek.add(const Duration(seconds: 1)));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TimeTrackerProvider>(context);
    final weekEntries = _getWeekEntries(provider);
    final startOfWeek = _getStartOfWeek(_selectedDate);
    final endOfWeek = startOfWeek.add(
      const Duration(days: 6, hours: 23, minutes: 59),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Week Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.grey),
                onPressed: () => _changeWeek(-1),
              ),
              Column(
                children: [
                  Text(
                    '${DateFormat('MMM d').format(startOfWeek)} - ${DateFormat('MMM d, yyyy').format(endOfWeek)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Start Day Selector
                  PopupMenuButton<int>(
                    initialValue: _startDay,
                    onSelected: (val) {
                      setState(() {
                        _startDay = val;
                      });
                    },
                    color: Colors.grey.shade900,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Starts on: ${_weekDayName(_startDay)}',
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_drop_down,
                            size: 14,
                            color: AppColors.accent,
                          ),
                        ],
                      ),
                    ),
                    itemBuilder: (context) {
                      return List.generate(7, (index) {
                        // Mon=1 ... Sun=7
                        final day = index + 1;
                        return PopupMenuItem(
                          value: day,
                          child: Text(
                            _weekDayName(day),
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      });
                    },
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.grey),
                onPressed: () => _changeWeek(1),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // 1. Time Allocation Donut
          _buildSectionLabel('1. TIME ALLOCATION'),
          const SizedBox(height: 16),
          _buildTimeAllocationChart(weekEntries, provider),
          const SizedBox(height: 30),

          // 2. Daily Activity (Bar Chart)
          _buildSectionLabel('2. DAILY ACTIVITY'),
          const SizedBox(height: 16),
          _buildDailyChart(weekEntries, startOfWeek),
          const SizedBox(height: 30),

          // 3. Breakdown
          _buildSectionLabel('3. WEEKLY BREAKDOWN'),
          const SizedBox(height: 16),
          _buildTaskBreakdown(weekEntries, provider),
          const SizedBox(height: 30),

          // 4. Goals vs Actual
          _buildSectionLabel('4. WEEKLY GOALS'),
          const SizedBox(height: 16),
          _buildGoalsVsActual(weekEntries, provider),
          const SizedBox(height: 30),

          // 5. Attendance Summary
          if (provider.goals.any((g) => g.contributionType == 'event')) ...[
            _buildSectionLabel('5. ATTENDANCE'),
            const SizedBox(height: 16),
            _buildAttendanceSummary(provider),
            const SizedBox(height: 30),
          ],
        ],
      ),
    );
  }

  String _weekDayName(int day) {
    switch (day) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Day $day';
    }
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.grey.shade500,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  // --- Chart Helpers ---

  Widget _buildTimeAllocationChart(
    List<TimeEntry> entries,
    TimeTrackerProvider provider,
  ) {
    if (entries.isEmpty) {
      return _buildEmptyState('No tracked time this week');
    }

    // Aggregation logic
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
      } else if (type == 'WASTED' || type == 'LEISURE')
        distribution['Wasted'] = distribution['Wasted']! + duration;
      else if (type == 'PERSONAL' || type == 'HEALTH')
        distribution['Personal'] = distribution['Personal']! + duration;
      else if (type == 'SLEEP')
        distribution['Sleep'] = distribution['Sleep']! + duration;
      else
        distribution['Unassigned'] = distribution['Unassigned']! + duration;
    }

    final totalMinutes = distribution.values.reduce((a, b) => a + b);
    if (totalMinutes == 0) return _buildEmptyState('No activity');

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
                      _formatMin(totalMinutes),
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
                    '${e.key}: ${_formatMin(e.value)}',
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

  Widget _buildDailyChart(List<TimeEntry> entries, DateTime startOfWeek) {
    // Aggregate by day (0..6)
    final dayTotals = List<double>.filled(7, 0.0);
    final dayLabels = <int, String>{};

    for (int i = 0; i < 7; i++) {
      final day = startOfWeek.add(Duration(days: i));
      dayLabels[i] = DateFormat('E').format(day); // Mon, Tue...
      // Sum entries
      final dailyEntries = entries.where(
        (e) =>
            DateFormat('yyyyMMdd').format(e.startTime) ==
            DateFormat('yyyyMMdd').format(day),
      );
      double sum = 0;
      for (var e in dailyEntries) {
        sum += (e.duration.inMinutes / 60.0);
      }
      dayTotals[i] = sum;
    }

    final maxHours = dayTotals.reduce(
      (curr, next) => curr > next ? curr : next,
    );
    final maxY = (maxHours * 1.2).ceilToDouble();
    final effectiveMaxY = maxY < 5 ? 5.0 : maxY;

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
      ),
      child: BarChart(
        BarChartData(
          maxY: effectiveMaxY,
          barGroups: List.generate(7, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: dayTotals[i],
                  color: AppColors.accent,
                  width: 14,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: effectiveMaxY,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ],
            );
          }),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      dayLabels[val.toInt()] ?? '',
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}h',
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: effectiveMaxY / 5,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.white.withOpacity(0.05), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          alignment: BarChartAlignment.spaceAround,
        ),
      ),
    );
  }

  Widget _buildTaskBreakdown(
    List<TimeEntry> entries,
    TimeTrackerProvider provider,
  ) {
    if (entries.isEmpty) return _buildEmptyState('No data for this week');

    final Map<String, _WeekTaskStat> taskStats = {};
    for (var e in entries) {
      final task = provider.getTaskById(e.taskId);
      final name = task?.name ?? 'Unknown';
      final key = task?.id ?? 'unknown';
      taskStats.putIfAbsent(
        key,
        () => _WeekTaskStat(name: name, color: task?.color ?? Colors.grey),
      );
      taskStats[key]!.totalMinutes += e.duration.inMinutes;
      final dayKey = DateFormat('yyyyMMdd').format(e.startTime);
      taskStats[key]!.activeDays.add(dayKey);
    }

    final sorted = taskStats.values.toList()
      ..sort((a, b) => b.totalMinutes.compareTo(a.totalMinutes));
    final maxMin = sorted.isNotEmpty ? sorted.first.totalMinutes : 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: sorted.take(10).map((stat) {
          final factor = (stat.totalMinutes / maxMin).clamp(0.01, 1.0);
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
                        stat.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          _formatMin(stat.totalMinutes),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
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
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 8,
                  width: double.infinity,
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    widthFactor: factor,
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

  Widget _buildGoalsVsActual(
    List<TimeEntry> entries,
    TimeTrackerProvider provider,
  ) {
    // Filter out event-based goals (Attendance)
    final goals = provider.goals
        .where((g) => g.contributionType != 'event')
        .toList();
    if (goals.isEmpty) return _buildEmptyState('No time-based goals set');

    // Target for week = goal.targetMinutes * 7.
    // Assuming goal.targetMinutes is DAILY.
    const int daysInWeek = 7;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: goals.map((goal) {
          final targetMinutes = goal.targetMinutes * daysInWeek;
          int actualMinutes = 0;
          if (goal.taskId == null) {
            // Global goal
            actualMinutes = entries.fold(
              0,
              (sum, e) => sum + e.duration.inMinutes,
            );
          } else {
            // Task specific logic
            // Note: simple filtration
            actualMinutes = entries
                .where((e) => e.taskId == goal.taskId)
                .fold(0, (sum, e) => sum + e.duration.inMinutes);
          }

          final progress = targetMinutes > 0
              ? (actualMinutes / targetMinutes).clamp(0.0, 1.5)
              : 0.0;
          final isOver = actualMinutes > targetMinutes;

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
                      '${_formatMin(actualMinutes)} / ${_formatMin(targetMinutes)}',
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
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: Color(goal.colorValue),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    if (isOver)
                      Positioned(
                        right: 0,
                        child: Icon(
                          Icons.warning,
                          color: Colors.orange,
                          size: 12,
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

  Widget _buildEmptyState(String msg) {
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(msg, style: const TextStyle(color: Colors.grey)),
      ),
    );
  }

  String _formatMin(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  Widget _buildAttendanceSummary(TimeTrackerProvider provider) {
    final attendanceGoals = provider.goals
        .where((g) => g.contributionType == 'event')
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: attendanceGoals.map((goal) {
          final stats = provider.getAttendanceStats(goal);
          // For weekly view, let's show Week stats specifically
          final attended = stats['week'] ?? 0;
          final total = stats['weekTotal'] ?? 0;
          final color = Color(goal.colorValue);

          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Matches: "${goal.eventTitlePattern ?? goal.taskId}"',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Text(
                    '$attended/$total This Week',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
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
}

class _WeekTaskStat {
  String name;
  Color color;
  int totalMinutes = 0;
  Set<String> activeDays = {};

  _WeekTaskStat({required this.name, required this.color});
}
