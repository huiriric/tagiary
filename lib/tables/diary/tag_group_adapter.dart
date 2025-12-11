import 'package:hive/hive.dart';
import 'package:mrplando/tables/diary/tag_group.dart';

class TagGroupAdapterWithMigration extends TypeAdapter<TagGroup> {
  @override
  final int typeId = 9;

  @override
  TagGroup read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return TagGroup(
      id: fields[0] as int,
      name: fields[1] as String,
      colorValue: fields[2] as int,
      // 기존 데이터에 isDeleted 필드가 없으면 false로 기본값 설정
      isDeleted: fields[3] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, TagGroup obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.colorValue)
      ..writeByte(3)
      ..write(obj.isDeleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TagGroupAdapterWithMigration &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
