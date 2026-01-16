import 'package:hive/hive.dart';
import 'package:mrplando/features/routine/models/routine_history.dart';
part 'check_routine_item.g.dart';

@HiveType(typeId: 3)
class CheckRoutineItem extends HiveObject {
  @HiveField(0)
  late int id;

  @HiveField(1)
  final String content;

  @HiveField(2)
  final DateTime startDate;

  @HiveField(3)
  final int colorValue;

  @HiveField(4)
  late bool check;

  @HiveField(5)
  late DateTime updated;

  @HiveField(6)
  final List<bool> daysOfWeek; // 요일별 반복 여부 [일, 월, 화, 수, 목, 금, 토]

  @HiveField(7)
  final DateTime? endDate; // 루틴 종료일 (null이면 무기한)

  @HiveField(8)
  final int? categoryId;

  CheckRoutineItem({
    required this.id,
    required this.content,
    required this.startDate,
    required this.colorValue,
    required this.check,
    required this.updated,
    required this.daysOfWeek,
    this.endDate,
    this.categoryId,
  });

  // copyWith 메서드 - 일부 필드만 변경할 때 사용
  CheckRoutineItem copyWith({
    int? id,
    String? content,
    DateTime? startDate,
    int? colorValue,
    bool? check,
    DateTime? updated,
    List<bool>? daysOfWeek,
    DateTime? endDate,
    int? categoryId,
  }) {
    return CheckRoutineItem(
      id: id ?? this.id,
      content: content ?? this.content,
      startDate: startDate ?? this.startDate,
      colorValue: colorValue ?? this.colorValue,
      check: check ?? this.check,
      updated: updated ?? this.updated,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      endDate: endDate ?? this.endDate,
      categoryId: categoryId ?? this.categoryId,
    );
  }

  // 기존 데이터와의 호환성을 위한 팩토리 생성자
  factory CheckRoutineItem.fromLegacy({
    required int id,
    required String content,
    required DateTime startDate,
    required int colorValue,
    required bool check,
    required DateTime updated,
  }) {
    return CheckRoutineItem(
      id: id,
      content: content,
      startDate: startDate,
      colorValue: colorValue,
      check: check,
      updated: updated,
      daysOfWeek: List.generate(7, (index) => true), // 기본적으로 모든 요일 선택
    );
  }
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

  List<CheckRoutineItem> getCategoryItems(int categoryId) {
    return _item.values.where((item) => item.categoryId == categoryId).toList();
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
        final updated = e.copyWith(check: false);
        await updateItem(updated);
      }
    }
  }

  // 루틴 체크 시 히스토리에 기록하는 메소드
  Future<void> checkRoutine(CheckRoutineItem routine, bool checked) async {
    // Create routine history repository
    final historyRepo = RoutineHistoryRepository();
    await historyRepo.init();

    // Update the routine check status
    final updatedRoutine = routine.copyWith(
      check: checked,
      updated: DateTime.now(),
    );
    await updateItem(updatedRoutine);

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

  // 마이그레이션: categoryId가 null인 항목을 기본 카테고리(1)로 업데이트
  Future<void> migrateToCategorySystem() async {
    final items = getAllItems();
    bool hasNullCategory = items.any((item) => item.categoryId == null);

    if (hasNullCategory) {
      for (var item in items) {
        if (item.categoryId == null) {
          // copyWith를 사용하여 categoryId만 업데이트
          final updatedItem = item.copyWith(categoryId: 1); // 기본 카테고리 ID
          await updateItem(updatedItem);
        }
      }
    }
  }
}
