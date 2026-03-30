// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scheduled_event.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScheduledEventAdapter extends TypeAdapter<ScheduledEvent> {
  @override
  final int typeId = 2;

  @override
  ScheduledEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScheduledEvent(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String?,
      startTime: fields[3] as DateTime,
      endTime: fields[4] as DateTime,
      colorValue: fields[5] as int,
      isAllDay: fields[6] as bool,
      linkedTaskId: fields[7] as String?,
      recurrenceType: fields[8] as String,
      recurrenceEndTime: fields[9] as DateTime?,
      recurrenceDays: (fields[10] as List?)?.cast<int>(),
      isCompleted: fields[11] as bool,
      completedDates: (fields[12] as List?)?.cast<DateTime>(),
      excludedDates: (fields[13] as List?)?.cast<DateTime>(),
    );
  }

  @override
  void write(BinaryWriter writer, ScheduledEvent obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.startTime)
      ..writeByte(4)
      ..write(obj.endTime)
      ..writeByte(5)
      ..write(obj.colorValue)
      ..writeByte(6)
      ..write(obj.isAllDay)
      ..writeByte(7)
      ..write(obj.linkedTaskId)
      ..writeByte(8)
      ..write(obj.recurrenceType)
      ..writeByte(9)
      ..write(obj.recurrenceEndTime)
      ..writeByte(10)
      ..write(obj.recurrenceDays)
      ..writeByte(11)
      ..write(obj.isCompleted)
      ..writeByte(12)
      ..write(obj.completedDates)
      ..writeByte(13)
      ..write(obj.excludedDates);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduledEventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
