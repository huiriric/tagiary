import 'package:hive/hive.dart';
import 'package:tagiary/tables/check_routine/routine_history.dart';
part 'check_routine_item.g.dart';

@HiveType(typeId: 3)
class CheckRoutineItem extends HiveObject {
  @HiveField(0)
  late int id;

  @HiveField(1)
  final String content;

  // @HiveField(2)
  // final String? endDate;

  @HiveField(2)
  final int colorValue;

  @HiveField(3)
  late bool check;

  @HiveField(4)
  late DateTime updated;

  CheckRoutineItem({
    required this.id,
    required this.content,
    // required this.endDate,
    required this.colorValue,
    required this.check,
    required this.updated,
  });
}

class CheckRoutineRepository {
  static const String itemCounterKey = 'itemCounter';

  late Box<CheckRoutineItem> _item;
  late Box<int> _counter;

  Future<void> init() async {
    _item = await Hive.openBox<CheckRoutineItem>('checkRoutineBox');
    _counter = await Hive.openBox<int>('counterBox');
  }

  Future<int> addItem(CheckRoutineItem item) async {
    int currentId = _counter.get(itemCounterKey, defaultValue: 0)!;
    int newId = currentId + 1;

    item.id = newId;
    item.updated = DateTime.now();
    await _item.put(newId, item);
    await _counter.put(itemCounterKey, newId);

    return newId;
  }

  CheckRoutineItem? getItem(int id) {
    return _item.get(id);
  }

  List<CheckRoutineItem> getAllItems() {
    return _item.values.toList();
  }

  List<CheckRoutineItem> getCheckedItems() {
    return _item.values.where((item) => item.check == true).toList();
  }

  List<CheckRoutineItem> getUnCheckdItems() {
    return _item.values.where((item) => item.check == false).toList();
  }

  Future<void> updateItem(CheckRoutineItem item) async {
    await _item.put(item.id, item);
  }

  Future<void> deleteItem(int id) async {
    await _item.delete(id);
  }

  Future<void> initializeRoutine() async {
    List<CheckRoutineItem> list = _item.values.toList();
    for (var e in list) {
      if (isBeforeToday(e.updated) && e.check) {
        e.check = false;
        updateItem(e);
      }
    }
  }

  // 루틴 체크 시 히스토리에 기록하는 메소드
  Future<void> checkRoutine(CheckRoutineItem routine, bool checked) async {
    // Create routine history repository
    final historyRepo = RoutineHistoryRepository();
    await historyRepo.init();

    // Update the routine check status
    routine.check = checked;
    routine.updated = DateTime.now();
    await updateItem(routine);

    // If checking the routine (not unchecking), record in history
    if (checked) {
      final history = RoutineHistory(
        id: 0, // Repository will assign ID
        routineId: routine.id,
        completedDate: DateTime.now(),
      );
      await historyRepo.addItem(history);
    }
  }

  bool isBeforeToday(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final compareDate = DateTime(date.year, date.month, date.day);

    return compareDate.isBefore(today);
  }
}
