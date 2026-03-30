// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deadline_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DeadlineItemAdapter extends TypeAdapter<DeadlineItem> {
  @override
  final int typeId = 6;

  @override
  DeadlineItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DeadlineItem(
      id: fields[0] as String,
      title: fields[1] as String,
      dueDate: fields[2] as DateTime,
      taskCategoryId: fields[3] as String,
      status: fields[4] as String,
      estimatedMinutes: fields[5] as int?,
      notes: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, DeadlineItem obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.dueDate)
      ..writeByte(3)
      ..write(obj.taskCategoryId)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.estimatedMinutes)
      ..writeByte(6)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeadlineItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
