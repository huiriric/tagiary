import 'package:hive/hive.dart';
import 'package:tagiary/tables/schedule_routine/schedule_routine_item.dart';

class ScheduleRoutineItemAdapter extends TypeAdapter<ScheduleRoutineItem> {
  @override
  final int typeId = 1;

  @override
  ScheduleRoutineItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    // 안전하게 daysOfWeek 필드 처리
    List<bool> daysOfWeek;
    try {
      // 필드가 있으면 변환 시도
      if (fields.containsKey(3)) {
        final fieldValue = fields[3];
        if (fieldValue is List) {
          daysOfWeek = List<bool>.from(fieldValue.map((item) => item is bool ? item : false));
        } else {
          // 필드가 List가 아니면 기본값 사용
          daysOfWeek = List.filled(7, false);
        }
      } else {
        // 필드가 없으면 기본값 사용
        daysOfWeek = List.filled(7, false);
      }
    } catch (e) {
      // 예외 발생 시 기본값 사용
      print("Error reading daysOfWeek field: $e");
      daysOfWeek = List.filled(7, false);
    }

    return ScheduleRoutineItem(
      title: fields[1] as String? ?? '',
      description: fields[2] as String? ?? '',
      startHour: fields[4] as int? ?? 0,
      startMinute: fields[5] as int? ?? 0,
      endHour: fields[6] as int? ?? 0,
      endMinute: fields[7] as int? ?? 0,
      colorValue: fields[8] as int? ?? 0,
      daysOfWeek: daysOfWeek,
    )..id = fields[0] as int? ?? 0;
  }

  @override
  void write(BinaryWriter writer, ScheduleRoutineItem obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.daysOfWeek)
      ..writeByte(4)
      ..write(obj.startHour)
      ..writeByte(5)
      ..write(obj.startMinute)
      ..writeByte(6)
      ..write(obj.endHour)
      ..writeByte(7)
      ..write(obj.endMinute)
      ..writeByte(8)
      ..write(obj.colorValue);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleRoutineItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}