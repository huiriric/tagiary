import 'package:hive/hive.dart';
import 'package:mrplando/tables/check_routine/routine_history.dart';

class RoutineHistoryAdapter extends TypeAdapter<RoutineHistory> {
  @override
  final int typeId = 5; // 동일한 typeId 사용

  @override
  RoutineHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return RoutineHistory(
      id: fields[0] as int? ?? 0,
      routineId: fields[1] as int? ?? 0,
      completedDate: fields[2] as DateTime? ?? DateTime.now(),
    );
  }

  @override
  void write(BinaryWriter writer, RoutineHistory obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.routineId)
      ..writeByte(2)
      ..write(obj.completedDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RoutineHistoryAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
