import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

part 'task_node.g.dart';

@HiveType(typeId: 0)
class TaskNode extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? subtitle;

  @HiveField(3)
  final String category; // User-created category name

  @HiveField(4)
  final int colorValue;

  @HiveField(5)
  final String baseType; // DEEP WORK, PERSONAL, WASTED, SLEEP, UNKNOWN

  @HiveField(6)
  final String? linkedInputId; // Link to Learning Hub Input

  TaskNode({
    required this.id,
    required this.name,
    this.subtitle,
    this.category = '',
    required this.colorValue,
    this.baseType = 'DEEP WORK',
    this.linkedInputId,
  });

  Color get color => Color(colorValue);

  static const String unknownId = 'unknown_task';
}
