import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/time_tracking_provider.dart';
import '../models/task_node.dart';
import '../constants/colors.dart';

class FullDayScreen extends StatelessWidget {
  const FullDayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TimeTrackerProvider>(context);
    final todayEntries = provider.getTodayEntries();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "TODAY'S REALITY",
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 14,
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: todayEntries.isEmpty
          ? Center(
              child: Text(
                'No entries yet',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: todayEntries.length,
              itemBuilder: (context, index) {
                final entry = todayEntries[index];
                final task = provider.getTaskById(entry.taskId);
                final isUnknown = task?.id == TaskNode.unknownId;
                final timeStr = DateFormat('h:mm a').format(entry.startTime);
                final durationStr =
                    '${entry.duration.inHours.toString().padLeft(2, '0')}:${entry.duration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${entry.duration.inSeconds.remainder(60).toString().padLeft(2, '0')}';
                final isLast = index == todayEntries.length - 1;

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 42,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: Text(
                            timeStr,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            margin: const EdgeInsets.only(top: 16),
                            decoration: BoxDecoration(
                              color: isUnknown
                                  ? AppColors.unknown
                                  : (task?.color ?? Colors.grey),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey.shade800,
                                width: 2,
                              ),
                            ),
                          ),
                          if (!isLast)
                            Expanded(
                              child: Container(
                                width: 2,
                                color: Colors.grey.shade800,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade900,
                            borderRadius: BorderRadius.circular(14),
                            border: isUnknown
                                ? Border.all(
                                    color: AppColors.unknown.withValues(
                                      alpha: 0.35,
                                    ),
                                  )
                                : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      task?.name ?? 'Unknown',
                                      style: TextStyle(
                                        color: isUnknown
                                            ? AppColors.unknown
                                            : AppColors.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    durationStr,
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 14,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (task?.subtitle != null &&
                                  task!.subtitle!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    task.subtitle!,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              if (entry.note != null && entry.note!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '"${entry.note}"',
                                      style: TextStyle(
                                        color: AppColors.accent.withValues(
                                          alpha: 0.8,
                                        ),
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ),
                              if (task?.baseType != null &&
                                  task!.baseType.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getBaseTypeColor(
                                        task.baseType,
                                      ).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      task.baseType,
                                      style: TextStyle(
                                        color: _getBaseTypeColor(task.baseType),
                                        fontSize: 9,
                                        letterSpacing: 0.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
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

  Color _getBaseTypeColor(String baseType) {
    switch (baseType) {
      case 'DEEP WORK':
        return AppColors.accent;
      case 'PERSONAL':
        return Colors.blue;
      case 'WASTED':
        return Colors.purple;
      case 'SLEEP':
        return Colors.teal;
      case 'UNKNOWN':
        return AppColors.unknown;
      default:
        return Colors.grey;
    }
  }
}
