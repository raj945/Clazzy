// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'learning_input.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LearningInputAdapter extends TypeAdapter<LearningInput> {
  @override
  final int typeId = 5;

  @override
  LearningInput read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LearningInput(
      id: fields[0] as String,
      title: fields[1] as String,
      type: fields[2] as String,
      source: fields[3] as String,
      status: fields[4] as String,
      tags: (fields[5] as List).cast<String>(),
      createdAt: fields[6] as DateTime,
      completedAt: fields[7] as DateTime?,
      linkedTaskId: fields[8] as String?,
      notes: fields[9] as String?,
      estimatedMinutes: fields[10] as int,
      url: fields[11] as String?,
      description: fields[12] as String?,
      relatedIds: fields[13] == null ? [] : (fields[13] as List).cast<String>(),
      displayMode: fields[14] == null ? 'list' : fields[14] as String,
    );
  }

  @override
  void write(BinaryWriter writer, LearningInput obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.source)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.tags)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.completedAt)
      ..writeByte(8)
      ..write(obj.linkedTaskId)
      ..writeByte(9)
      ..write(obj.notes)
      ..writeByte(10)
      ..write(obj.estimatedMinutes)
      ..writeByte(11)
      ..write(obj.url)
      ..writeByte(12)
      ..write(obj.description)
      ..writeByte(13)
      ..write(obj.relatedIds)
      ..writeByte(14)
      ..write(obj.displayMode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearningInputAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
