import 'package:hive/hive.dart';

part 'check_enum.g.dart';

@HiveType(typeId: 10)
enum CheckEnum {
  @HiveField(0)
  pending,

  @HiveField(1)
  inProgress,

  @HiveField(2)
  done,
}
