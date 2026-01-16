import 'package:hive/hive.dart';
import 'package:mrplando/shared/models/check_enum.dart';
part 'check_item.g.dart';

@HiveType(typeId: 2)
class CheckItem extends HiveObject {
  @HiveField(0)
  late int id;

  @HiveField(1)
  final String content;

  @HiveField(2)
  final String? dueDate;

  @HiveField(3)
  final String? startDate;

  @HiveField(4)
  final String? doneDate;

  @HiveField(5)
  final int colorValue;

  @HiveField(6)
  final CheckEnum check;

  @HiveField(7)
  final int? categoryId;

  CheckItem({
    required this.id,
    required this.content,
    required this.dueDate,
    required this.startDate,
    required this.doneDate,
    required this.colorValue,
    required this.check,
    this.categoryId,
  });
}

class CheckRepository {
  static const String itemCounterKey = 'itemCounter';

  late Box<CheckItem> _item;
  late Box<int> _counter;

  Future<void> init() async {
    _item = await Hive.openBox<CheckItem>('checkBox');
    _counter = await Hive.openBox<int>('counterBox');
  }

  Future<int> addItem(CheckItem item) async {
    int currentId = _counter.get(itemCounterKey, defaultValue: 0)!;
    int newId = currentId + 1;

    item.id = newId;

    await _item.put(newId, item);
    await _counter.put(itemCounterKey, newId);

    return newId;
  }

  CheckItem? getItem(int id) {
    return _item.get(id);
  }

  List<CheckItem> getAllItems() {
    return _item.values.toList();
  }

  List<CheckItem> getCheckedItems() {
    return _item.values.where((item) => item.check == true).toList();
  }

  List<CheckItem> getUnCheckdItems() {
    return _item.values.where((item) => item.check == false).toList();
  }

  Future<void> updateItem(CheckItem item) async {
    await _item.put(item.id, item);
    getItem(item.id);
    print(item.startDate);
    print(item.doneDate);
  }

  Future<void> deleteItem(int id) async {
    await _item.delete(id);
  }

  // 마이그레이션: categoryId가 null인 항목을 기본 카테고리(1)로 업데이트
  Future<void> migrateToCategorySystem() async {
    final items = getAllItems();
    bool hasNullCategory = items.any((item) => item.categoryId == null);

    if (hasNullCategory) {
      for (var item in items) {
        if (item.categoryId == null) {
          // 새 CheckItem 생성 (categoryId를 1로 설정)
          final updatedItem = CheckItem(
            id: item.id,
            content: item.content,
            dueDate: item.dueDate,
            startDate: item.startDate,
            doneDate: item.doneDate,
            colorValue: item.colorValue,
            check: item.check,
            categoryId: 1, // 기본 카테고리 ID
          );
          await _item.put(item.id, updatedItem);
        }
      }
    }
  }
}
