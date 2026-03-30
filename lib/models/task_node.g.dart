// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_node.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskNodeAdapter extends TypeAdapter<TaskNode> {
  @override
  final int typeId = 0;

  @override
  TaskNode read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskNode(
      id: fields[0] as String,
      name: fields[1] as String,
      subtitle: fields[2] as String?,
      category: fields[3] as String,
      colorValue: fields[4] as int,
      baseType: fields[5] as String,
      linkedInputId: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TaskNode obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.subtitle)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.colorValue)
      ..writeByte(5)
      ..write(obj.baseType)
      ..writeByte(6)
      ..write(obj.linkedInputId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskNodeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
